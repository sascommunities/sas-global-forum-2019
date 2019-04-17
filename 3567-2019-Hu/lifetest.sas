/* Macro library for generating life-test tables
/* using lifetime data with or without competing risks
/* Maintainer: Zhen-Huan Hu <zhu@mcw.edu>
/* Last change: 2018-03-19
/*
/* -------------------------------------------- */
/* Functions and their basic uses:
/*
/* %lifetest(indata =, event =, competerisk =, intv =, ltime =, strata =, subgroup =, timelist =);
/* %lifetestexport(outdata =, rtftitle =);
/*
/* INDATA:	  Input dataset
/* EVENT:	  Event of interest (default: dead)
/* COMPETERISK:   Competing risk to the event of interest
/* INTV:	  Time to the event / right censoring
/* LTIME:         Left truncation time
/* STRATA:	  Main group
/* SUBGROUP:	  Secondary group (optional)
/* TIMELIST:	  Specific time points for survival estimates
/* OUTDATA:	  Output file name
/* RTFTITLE:	  Title for the output table
/* -------------------------------------------- */

%let lts_ttlcnt = 0; %* Total number of tables;
%let lts_colcnt = 0; %* Total number of columns;
%let lts_sttvar = ;

%let lts_preset_strata = ;
%let lts_preset_pwpvalue = ;
%let lts_preset_natrisk = ;
%let lts_preset_leftcheck = ;
%let lts_preset_conftype = ;
%let lts_preset_alpha = ;
%let lts_preset_abridged = ;

%macro lifetestreset();
  %let lts_ttlcnt = 0; %* Total number of tables;
  %let lts_colcnt = 0; %* Total number of columns;
  %let lts_sttvar = ;

  %let lts_preset_strata = ;
  %let lts_preset_pwpvalue = ;
  %let lts_preset_natrisk = ;
  %let lts_preset_leftcheck = ;
  %let lts_preset_conftype = ;
  %let lts_preset_alpha = ;
  %let lts_preset_abridged = ;
%mend;

%macro lifetestpreset(
  strata = , pwpvalue = , natrisk = , leftcheck = ,
  conftype = , alpha = , abridged = );

  %if &strata    ne %then %let lts_preset_strata    = &strata;
  %if &pwpvalue  ne %then %let lts_preset_pwpvalue  = &pwpvalue;
  %if &natrisk   ne %then %let lts_preset_natrisk   = &natrisk;
  %if &leftcheck ne %then %let lts_preset_leftcheck = &leftcheck;
  %if &conftype  ne %then %let lts_preset_conftype  = &conftype;
  %if &alpha     ne %then %let lts_preset_alpha     = &alpha;
  %if &abridged  ne %then %let lts_preset_abridged  = &abridged;
%mend;

%macro lifetest(
  indata = ,            /* Input SAS dataset */
  strata = nil,         /* Main group */
  subgroup = ,          /* Secondary group (optional) */
  event = dead,         /* Event of interest */
  intv = intxsurv,      /* Time to event */
  ltime = ,             /* Left truncation time */
  competerisk = ,       /* Competing risk */
  timelist = 12 36 60,  /* Time points of the estimates */
  pwpvalue = 0,         /* Toggle point-wise p-values */
  natrisk = 0,          /* Toggle number at risk */
  conftype = 2,         /* Confidence interval transformation */
  alpha = 0.05,         /* Alpha level */
  flemingp = 0,         /* Fleming weight p */
  flemingq = 0,         /* Fleming weight q */
  failure = 0,          /* Use failure rates as results */
  leftcheck = 1,        /* Ignore the estimates if <= 15 obs left */
  abridged = 0          /* Abridged look */
  );

  %* Precheck data are ready;
  %if &indata eq %then %do;
    %put ERROR: Please specify input data set;
    %return;
  %end;
  %else %if not %sysfunc(exist(&indata)) %then %do;
    %put ERROR: Input data set not available;
    %return;
  %end;

  %* Use preset to overwrite values;
  %if &lts_preset_strata    ne %then %let strata    = &lts_preset_strata;
  %if &lts_preset_pwpvalue  ne %then %let pwpvalue  = &lts_preset_pwpvalue;
  %if &lts_preset_natrisk   ne %then %let natrisk   = &lts_preset_natrisk;
  %if &lts_preset_leftcheck ne %then %let leftcheck = &lts_preset_leftcheck;
  %if &lts_preset_conftype  ne %then %let conftype  = &lts_preset_conftype;
  %if &lts_preset_alpha     ne %then %let alpha     = &lts_preset_alpha;
  %if &lts_preset_abridged  ne %then %let abridged  = &lts_preset_abridged;

  %* Precheck if strata variable changed;
  %if &lts_sttvar = %then %let lts_sttvar = &strata;
  %else %if &lts_sttvar ne &strata %then %do;
    %put ERROR: Changed main group variable;
    %return;
  %end;

  %* Varify alpha value;
  %if &alpha <= 0 or &alpha >= 1 %then %do;
    %put ERROR: Invalid alpha value;
    %return;
  %end;

  %if &subgroup = %then %do;
    %lifetestlite(indata = &indata, strata = &strata,
    event = &event, intv = &intv, ltime = &ltime, competerisk = &competerisk, timelist = &timelist,
    pwpvalue = &pwpvalue, natrisk = &natrisk, leftcheck = &leftcheck,
    conftype = &conftype, alpha = &alpha, flemingp = &flemingp, flemingq = &flemingq,
    failure = &failure, abridged = &abridged);
  %end;
  %else %do;
    %lifetestpro(indata = &indata, strata = &strata, subgroup = &subgroup,
    event = &event, intv = &intv, ltime = &ltime, competerisk = &competerisk, timelist = &timelist,
    pwpvalue = &pwpvalue, natrisk = &natrisk, leftcheck = &leftcheck,
    conftype = &conftype, alpha = &alpha, flemingp = &flemingp, flemingq = &flemingq,
    failure = &failure, abridged = &abridged);
  %end;
%mend lifetest;

%macro lifetestlite(
  indata = ,            /* Input SAS dataset */
  strata = nil,         /* Main group */
  event = dead,         /* Event of interest */
  competerisk = ,       /* Competing risk */
  intv = intxsurv,      /* Time to event */
  ltime = ,             /* Left truncation time */
  timelist = 12 36 60,  /* Specific time points for estimation */
  pwpvalue = 0,         /* Toggle point-wise p-values */
  natrisk = 0,          /* Toggle number at risk */
  leftcheck = 1,        /* Ignore the estimate if less than 15 obs left */
  conftype = 2,         /* Type of transformation used when calculating confidence limits */
  alpha = 0.05,         /* Alpha level */
  flemingp = 0,         /* Fleming weight p */
  flemingq = 0,         /* Fleming weight q */
  failure = 0,          /* Use failure rates as results */
  abridged = 0          /* Abridged look */
  );

  %if &competerisk ~= %then %let failure = 1;
  %if &abridged %then %do;
    %let natrisk = 1;
    %let pwpvalue = 1;
  %end;

  proc format; value nil 1 = 'Study population';

  %* Count # of obs by strata;
  %* Initialize global macro variables;
  data _init_;
    set &indata;
    %if &strata = nil %then %do; nil = 1; format nil nil.; %end;
    %else %do; where not missing(&strata); %end;
    keep &strata &event &competerisk &intv &ltime;
    call symput('eventlabel', vlabel(&event));
  run;

  proc freq data = _init_ noprint;
    tables &strata / out = _overall_strata_;
  proc sort data = _overall_strata_; by &strata;
  proc transpose data = _overall_strata_ out = _overall_t_strata_(drop = _name_ _label_);
    var count;
    id &strata;
    idlabel &strata;
  run;
  proc contents data = _overall_t_strata_ out = _overall_t_strata_vars_(keep = varnum name label) noprint;
  proc sort data = _overall_t_strata_vars_; by varnum;

  %global lts_colcnt;
  data _null_;
    set _overall_strata_ end = eof;
    if eof then call symput('lts_colcnt', strip(put(_n_, best.)));
  run;
  %do i = 1 %to &lts_colcnt;
    %global sttvar&i sttlab&i sttcnt&i;
  %end;
  data _null_;
    set _overall_t_strata_vars_;
    call symput(cats('sttvar', _n_), strip(name));
    if strip(label) ne '' then call symput(cats('sttlab', _n_), prxchange('s/^-?\d+\.?\s+//', 1, strip(label)));
    else call symput(cats('sttlab', _n_), strip(name));
  run;
  data _null_;
    set _overall_strata_;
    call symput(cats('sttvalue', _n_), strip(put(&strata, best.)));
    call symput(cats('sttcnt', _n_), strip(put(count, best.)));
  run;

  %* Preload dataset for analysis;
  data _lifetest_init_;
    set _init_;
    where &intv >= 0 and &event in (0, 1) %if &competerisk ~= %then and &competerisk in (0, 1);;
    %* Create STATUS variable as required for calculating CIF;
    if &event = 1 then status = 1;
    %if &competerisk ~= %then %do;
      else if &competerisk = 1 then status = 2;
      else if &event = 0 and &competerisk = 0 then status = 0;
    %end;
    %else %do;
      else if &event = 0 then status = 0;
    %end;
  run;

  %* Actual analysis;
  %lifetestcore(indata = _lifetest_init_, status = status,
  strata = &strata, intv = &intv, ltime = &ltime, timelist = &timelist,
  pwpvalue = &pwpvalue, natrisk = &natrisk, leftcheck = &leftcheck,
  conftype = &conftype, alpha = &alpha, flemingp = &flemingp, flemingq = &flemingq,
  failure = &failure);

  %* Finalize;
  %let lts_ttlcnt = %eval(&lts_ttlcnt + 1);
  data tab&lts_ttlcnt;
    set _lt_results_;

    length varstr $ 100;
    if timelist = 0 then varstr = strip("&eventlabel");
    else if timelist = 0.921 then varstr = '28-day';
    else if 3.27 <= timelist <= 3.29 then varstr = '100-day';
    else if timelist = 3.75 then varstr = '114-day';
    else if timelist > 0 and mod(timelist, 12) = 0 then varstr = cat(round(timelist / 12), '-year');
    else varstr = cat(round(timelist), ' months');

    length pvalue $ 25;
    if p >= 0.01 then pvalue = strip(put(p, 4.2));
    else if p >= 0.001 then pvalue = strip(put(p, 5.3));
    else if p >= 0 then pvalue = '<0.001';

    %if &abridged %then %do;
      varstr = cats("&eventlabel", "/", varstr);
      if timelist = 0 then delete;
      else rwtype = 0;
    %end;
    %else %do;
      if timelist = 0 then rwtype = 0;
      else rwtype = 1;
    %end;

    drop timelist p;
  run;
%mend;

%macro lifetestpro(
  indata = ,            /* Input SAS dataset */
  strata = nil,         /* Main group */
  subgroup = ,          /* Secondary group */
  event = dead,         /* Event of interest */
  competerisk = ,       /* Competing risk */
  intv = intxsurv,      /* Time to event */
  ltime = ,             /* Left truncation time */
  timelist = 12 36 60,  /* Specific time points for estimation */
  pwpvalue = 0,         /* Toggle point-wise p-values */
  natrisk = 0,          /* Toggle number at risk */
  leftcheck = 1,        /* Ignore the estimate if less than 15 obs left */
  conftype = 2,         /* Type of transformation used when calculating confidence limits */
  alpha = 0.05,         /* Alpha level */
  flemingp = 0,         /* Fleming weight p */
  flemingq = 0,         /* Fleming weight q */
  failure = 0,          /* Use failure rates as results */
  abridged = 0          /* Abridged look */
  );

  %if &competerisk ~= %then %let failure = 1;
  %if &abridged %then %do;
    %let natrisk = 1;
    %let pwpvalue = 1;
  %end;

  proc format; value nil 1 = 'Study population';

  %* Count # of obs by strata;
  %* Initialize global macro variables;
  data _init_;
    set &indata;
    %if &strata = nil %then %do; where not missing(&subgroup); nil = 1; format nil nil.; %end;
    %else %do; where not missing(&subgroup) and not missing(&strata); %end;
    keep &strata &subgroup &intv &event &competerisk;
    call symput('eventlabel', vlabel(&event));
  run;

  proc freq data = _init_ noprint;
    tables &strata / out = _overall_strata_;
  proc sort data = _overall_strata_; by &strata;
  proc transpose data = _overall_strata_ out = _overall_t_strata_(drop = _name_ _label_);
    var count;
    id &strata;
    idlabel &strata;
  run;
  proc contents data = _overall_t_strata_ out = _overall_t_strata_vars_(keep = varnum name label) noprint;
  proc sort data = _overall_t_strata_vars_; by varnum;

  %global lts_colcnt;
  data _null_;
    set _overall_strata_ end = eof;
    if eof then call symput('lts_colcnt', strip(put(_n_, best.)));
  run;
  %do i = 1 %to &lts_colcnt;
    %global sttvar&i sttlab&i sttcnt&i;
  %end;
  data _null_;
    set _overall_t_strata_vars_;
    call symput(cats('sttvar', _n_), strip(name));
    if strip(label) ne '' then call symput(cats('sttlab', _n_), prxchange('s/^-?\d+\.?\s+//', 1, strip(label)));
    else call symput(cats('sttlab', _n_), strip(name));
  run;
  data _null_;
    set _overall_strata_;
    call symput(cats('sttvalue', _n_), strip(put(&strata, best.)));
    call symput(cats('sttcnt', _n_), strip(put(count, best.)));
  run;

  %* Preload dataset for analysis;
  data _lifetest_init_;
    set _init_;
    where &intv >= 0 and &event in (0, 1) %if &competerisk ~= %then and &competerisk in (0, 1);;
    %* Create STATUS variable as required for calculating CIF;
    if &event = 1 then status = 1;
    %if &competerisk ~= %then %do;
      else if &competerisk = 1 then status = 2;
      else if &event = 0 and &competerisk = 0 then status = 0;
    %end;
    %else %do;
      else if &event = 0 then status = 0;
    %end;
  run;

  %* Count # of obs by sub-groups;
  proc freq data = _lifetest_init_ noprint;
    table &subgroup / out = _subgrp_;
  proc sort data = _subgrp_; by &subgroup;
  proc transpose data = _subgrp_ out = _t_subgrp_(drop = _name_ _label_);
    var count;
    id &subgroup;
    idlabel &subgroup;
  run;
  proc contents data = _t_subgrp_ out = _t_subgrp_vars_(keep = varnum name label) noprint;
  proc sort data = _t_subgrp_vars_; by varnum;

  data _null_;
    set _subgrp_ end = eof;
    if eof then call symput('subgrpcnt', strip(put(_n_, best.)));
  run;
  data _null_;
    set _t_subgrp_vars_;
    call symput(cats('subgrpvar', _n_), strip(name));
    if strip(label) ne '' then call symput(cats('subgrplab', _n_), prxchange('s/^-?\d+\.?\s+//', 1, strip(label)));
    else call symput(cats('subgrplab', _n_), strip(name));
  run;
  data _null_;
    set _subgrp_;
    call symput(cats('subgrpvalue', _n_), strip(put(&subgroup, best.)));
    call symput(cats('subgrpcnt', _n_), strip(put(count, best.)));
  run;

  /* Analysis for each subgrp */
  %do s = 1 %to &subgrpcnt;
    %* Keep obs within the sub-group;
    data _lifetest_subgrp_;
      set _lifetest_init_;
      where &subgroup = &&subgrpvalue&s;
    run;

    %* Acutal analysis;
    %lifetestcore(indata = _lifetest_subgrp_, status = status,
    strata = &strata, intv = &intv, ltime = &ltime, timelist = &timelist,
    pwpvalue = &pwpvalue, natrisk = &natrisk, leftcheck = &leftcheck,
    conftype = &conftype, alpha = &alpha, flemingp = &flemingp, flemingq = &flemingq,
    failure = &failure);

    %* Finalize;
    data _tab_&s;
      set _lt_results_;

      length varstr $ 100;
      if timelist = 0 then varstr = strip("&&subgrplab&s");
      else if timelist = 0.921 then varstr = '28-day';
      else if 3.27 <= timelist <= 3.29 then varstr = '100-day';
      else if timelist = 3.75 then varstr = '114-day';
      else if timelist > 0 and mod(timelist, 12) = 0 then varstr = cat(round(timelist / 12), '-year');
      else varstr = cat(round(timelist), ' months');

      length pvalue $ 25;
      if p >= 0.01 then pvalue = strip(put(p, 4.2));
      else if p >= 0.001 then pvalue = strip(put(p, 5.3));
      else if p >= 0 then pvalue = '< 0.001';

      %if &abridged %then %do;
        varstr = cats("&&subgrplab&s", "/", varstr);
        if timelist = 0 then delete;
        else rwtype = 1;
      %end;
      %else %do;
        if timelist = 0 then rwtype = 1;
        else rwtype = 2;
      %end;

      drop timelist p;
    run;
  %end;

  data _main_header_;
    length varstr $ 100;
    varstr = strip("&eventlabel");
    rwtype = 0;
  run;

  %let lts_ttlcnt = %eval(&lts_ttlcnt + 1);
  data tab&lts_ttlcnt;
    set _main_header_ _tab_1-_tab_&subgrpcnt;
  run;
%mend;

%macro lifetestcore(
  indata = ,            /* Input SAS dataset */
  strata = nil,         /* Main group */
  status = status,      /* Events: 0 - censoring, 1 - event of interest */
  intv = ,              /* Time to event */
  ltime = ,             /* Left truncation time */
  timelist = 12 36 60,  /* Specific time points for estimation */
  pwpvalue = 0,         /* Toggle point-wise p-values */
  natrisk = 0,          /* Toggle number at risk */
  leftcheck = 1,        /* Ignore the estimate if less than 15 obs left */
  conftype = 2,         /* Type of transformation used when calculating confidence limits */
  alpha = 0.05,         /* Alpha level */
  flemingp = 0,         /* Fleming weight p */
  flemingq = 0,         /* Fleming weight q */
  failure = 0,          /* Use failure rates as results */
  );

  %if &leftcheck %then %let atrisk_limit = 15;
  %else %let atrisk_limit = 1;

  proc sql noprint;
    select count(distinct &strata) into :strata_cnt trimmed from &indata;
    select count(&status) into :event_cnt trimmed from &indata where &status = 1;
  quit;

  %local estimate lcl ucl stderr atrisk;
  %if &event_cnt = 0 %then %do;
    %* Skip the analysis if no event happening;
    %* Create a dummy output dataset;
    proc freq data = &indata noprint;
      table &strata / out = _output_(drop = percent rename = (count = d_atrisk));
    data _output_;
      set _output_;
      length &intv timelist d_estimate d_lcl d_ucl d_stderr d_atrisk 8;
      &intv = 0; timelist = 0; output;
      %do t = 1 %to %sysfunc(countw(&timelist, %str( )));
        timelist = %sysfunc(scan(&timelist, &t));
        call missing(d_atrisk);
        output;
      %end;
    run;
    %let estimate = d_estimate;
    %let lcl = d_lcl;
    %let ucl = d_ucl;
    %let stderr = d_stderr;
    %let atrisk = d_atrisk;
  %end;
  %else %if &competerisk = %then %do;
    %* Survivor function;
    %if &ltime = %then %do;
      ods listing close;
      proc lifetest data = &indata timelist = 0 &timelist atrisk;
        time &intv * &status(0);
        strata &strata / test = fleming(&flemingp, &flemingq);
        ods output ProductLimitEstimates = _output_;
        %if &strata_cnt > 1 %then %do; ods output HomTests = _outtest_; %end;
      run;
      ods listing;
    %end;
    %else %do;
      %lt_lifetest(indata = &indata, strata = &strata,
      event = &status, intv = &intv, ltime = &ltime, timelist = &timelist, noprint = 1);

      %* Generate dummy time 0 rows;
      proc sql noprint;
        create table _lt_time0_ as
        select 0 as timelist, 1 as survival, &strata, count(*) as numberatrisk
        from &indata group by &strata;
      quit;

      data _output_;
        set _lt_time0_ _output_;
      run;

      %if &strata_cnt > 1 %then %do; %lt_logranktest(indata = &indata, strata = &strata,
      event = &status, intv = &intv, ltime = &ltime,
      flemingp = &flemingp, flemingq = &flemingq, noprint = 1); %end;
    %end;

    data _output_;
      set _output_;
      z = probit(1 - &alpha / 2.0);
      if survival = 1 and stderr = 0 then do;
        call missing(sdf_lcl); call missing(sdf_ucl);
        call missing(cdf_lcl); call missing(cdf_ucl);
      end;
      else do;
        %if &conftype = 1 %then %do;
          %* Confidence intervals: log-log tranformation;
          sdf_stderr = stderr / (survival * log(survival));
          sdf_lcl = survival ** exp(-z * sdf_stderr);
          sdf_ucl = survival ** exp(z * sdf_stderr);
          cdf_stderr = stderr / (failure * log(failure));
          cdf_lcl = failure ** exp(-z * cdf_stderr);
          cdf_ucl = failure ** exp(z * cdf_stderr);
        %end;
        %else %if &conftype = 2 %then %do;
          %* Confidence intervals: arcsine-square root tranformation;
          sdf_stderr = 0.5 * stderr / sqrt(survival * (1 - survival));
          sdf_lcl = sin(max(0, arsin(sqrt(survival)) - z * sdf_stderr)) ** 2;
          sdf_ucl = sin(min(3.1416 / 2, arsin(sqrt(survival)) + z * sdf_stderr)) ** 2;
          cdf_stderr = 0.5 * stderr / sqrt(failure * (1 - failure));
          cdf_lcl = sin(max(0, arsin(sqrt(failure)) - z * cdf_stderr)) ** 2;
          cdf_ucl = sin(min(3.1416 / 2, arsin(sqrt(failure)) + z * cdf_stderr)) ** 2;
        %end;
        %else %if &conftype = 3 %then %do;
          %* Confidence intervals: logit transformation;
          sdf_stderr = stderr / (survival * (1 - survival));
          sdf_lcl = survival / (survival + (1 - survival) * exp(z * sdf_stderr));
          sdf_ucl = survival / (survival + (1 - survival) * exp(-z * sdf_stderr));
          cdf_stderr = stderr / (failure * (1 - failure));
          cdf_lcl = failure / (failure + (1 - failure) * exp(z * cdf_stderr));
          cdf_ucl = failure / (failure + (1 - failure) * exp(-z * cdf_stderr));
        %end;
        %else %if &conftype = 4 %then %do;
          %* Confidence intervals: log transformation;
          sdf_stderr = stderr / survival;
          sdf_lcl = survival * exp(-z * sdf_stderr);
          sdf_ucl = survival * exp(z * sdf_stderr);
          cdf_stderr = stderr / failure;
          cdf_lcl = failure * exp(-z * cdf_stderr);
          cdf_ucl = failure * exp(z * cdf_stderr);
        %end;
      end;
    run;
    %if &failure = 0 %then %do;
      %let estimate = survival;
      %let lcl = sdf_lcl;
      %let ucl = sdf_ucl;
    %end;
    %else %if &failure = 1 %then %do;
      %let estimate = failure;
      %let lcl = cdf_lcl;
      %let ucl = cdf_ucl;
    %end;
    %let stderr = stderr;
    %let atrisk = numberatrisk;
  %end;
  %else %do;
    %* Cumulative incidence function;
    %let dsid = %sysfunc(open(&indata, i));
    %let snum = %sysfunc(varnum(&dsid, &strata));
    %let sfmt = %sysfunc(varfmt(&dsid, &snum));
    %let rc = %sysfunc(close(&dsid));

    ods listing close;
    proc lifetest data = &indata outcif = _output_complete_;
      strata &strata;
      time &intv * &status(0) / failcode = 1;
      %if &lts_colcnt > 1 %then %do; ods output GrayTest = _outtest_; %end;
    run;
    ods listing;

    proc sort data = _output_complete_;
      by &strata &intv;
    proc iml;
      use _output_complete_;
      read all var {&intv &strata};
      read all var {&intv &strata cif stderr atrisk} into cif_dblock;
      close _output_complete_;
      timelist = t(unique({0 &timelist}));
      nt = nrow(timelist); * N of t;
      bystrata = unique(&strata);
      ns = ncol(bystrata); * N of strata;
      cif_rblock = j(ns # nt, ncol(cif_dblock), .);
      do s = 1 to ns;
        bythisstrata = (&strata = bystrata[s]);
        do t = 1 to nt;
          bythisloc = max(loc(&intv <= timelist[t] & bythisstrata));
          cif_rblock[(s - 1) # nt + t, ] = cif_dblock[bythisloc, ];
        end;
      end;
      cif_rblock = shapecol(timelist, ns # nt, 1) || cif_rblock;
      create _output_ from cif_rblock[colname = {timelist &intv &strata cif stderr atrisk}];
      append from cif_rblock;
      close _output_;
    quit;

    data _output_;
      set _output_;
      z = probit(1 - &alpha / 2.0);
      if cif = 0 and stderr = 0 then do;
        call missing(cif_lcl);
        call missing(cif_ucl);
      end;
      else do;
        %if &conftype = 1 %then %do;
          %* Confidence intervals: log-log tranformation;
          cif_stderr = stderr / (cif * log(cif));
          cif_lcl = cif ** exp(-z * cif_stderr);
          cif_ucl = cif ** exp(z * cif_stderr);
        %end;
        %else %if &conftype = 2 %then %do;
          %* Confidence intervals: arcsine-square root tranformation;
          cif_stderr = 0.5 * stderr / sqrt(cif * (1 - cif));
          cif_lcl = sin(max(0, arsin(sqrt(cif)) - z * cif_stderr)) ** 2;
          cif_ucl = sin(min(3.1416 / 2, arsin(sqrt(cif)) + z * cif_stderr)) ** 2;
        %end;
        %else %if &conftype = 3 %then %do;
          %* Confidence intervals: logit transformation;
          cif_stderr = stderr / (cif * (1 - cif));
          cif_lcl = cif / (cif + (1 - cif) * exp(z * cif_stderr));
          cif_ucl = cif / (cif + (1 - cif) * exp(-z * cif_stderr));
        %end;
        %else %if &conftype = 4 %then %do;
          %* Confidence intervals: log transformation;
          cif_stderr = stderr / cif;
          cif_lcl = cif * exp(-z * cif_stderr);
          cif_ucl = cif * exp(z * cif_stderr);
        %end;
      end;
      format &strata &sfmt;
    run;
    %let estimate = cif;
    %let lcl = cif_lcl;
    %let ucl = cif_ucl;
    %let stderr = stderr;
    %let atrisk = atrisk;
  %end;

  %* Point-wise p-values;
  %if &strata_cnt > 1 and &pwpvalue %then %do;
    %multiztest(indata = _output_, mean = &estimate, std = &stderr, timelist = timelist);
  %end;

  %* Post-processing;
  data _output_;
    set _output_;

    est_100 = &estimate * 100;
    lcl_100 = &lcl * 100;
    ucl_100 = &ucl * 100;

    %* Combine estimates and CIs;
    length result $ 250;
    if timelist = 0 then result = '';
    else if &atrisk < &atrisk_limit then result = 'NE';
    else if est_100 = 100 then result = '100%';
    else if est_100 = 0 then result = '0%';
    else result = cat(round(est_100), ' (', round(lcl_100), '-', round(ucl_100), ')%');

    %* Count N at risk;
    length count $ 20;
    if timelist = 0 and &atrisk >= 0 then count = strip(put(&atrisk, best.));
    else if &natrisk and &atrisk >= 0 then count = strip(put(&atrisk, best.));

    %* Log problematic events;
    if 0 < &atrisk < 15 then put "WARNING: [&event, &strata: " &strata ", time: " timelist "] Only " &atrisk " at risk.";
    if timelist > 0 and &atrisk = 0 then put "WARNING [&event, &strata: " &strata ", time: " timelist "] No one at risk.";
    if timelist > 6 and timelist - &intv > 6 then put "WARNING: [&event, &strata: " &strata ", time: " timelist "] The actual event occurred at " &intv ".";
  run;

  %* Create result dataset;
  proc sort data = _output_; by timelist;
  proc transpose data = _output_ out = _lt_results_(drop = _name_);
    by timelist;
    var result;
    id &strata;
  run;
  %* N at risk;
  proc transpose data = _output_ out = _lt_natrisk_(drop = _name_) suffix = atrisk;
    by timelist;
    var count;
    id &strata;
  run;
  proc sort data = _lt_results_; by timelist;
  proc sort data = _lt_natrisk_; by timelist;
  data _lt_results_;
    merge _lt_results_ _lt_natrisk_;
    by timelist;
  run;
  %* Point-wise p-values;
  %if &strata_cnt > 1 and &event_cnt >= 1 and &pwpvalue %then %do;
    proc sort data = _lt_results_; by timelist;
    proc sort data = _pointwise_p_; by timelist;
    data _lt_results_;
      merge _lt_results_ _pointwise_p_;
      by timelist;
    run;
  %end;
  %* Overall p-value;
  %if &strata_cnt > 1 and &event_cnt >= 1 %then %do;
    data _overall_pvalue_;
      set _outtest_;
      rename probchisq = p;
      keep timelist probchisq;
      timelist = 0;
    run;
    proc sort data = _lt_results_; by timelist;
    proc sort data = _overall_pvalue_; by timelist;
    data _lt_results_;
      update _lt_results_ _overall_pvalue_;
      by timelist;
    run;
  %end;
%mend;

%macro lifetestexport(
  outdata = lifetest, /* Output SAS dataset */
  rtftitle =,         /* Title of the RTF file */
  pvalue = 1,         /* Show p-value in final report */
  style = kenyrtf     /* Output RTF style */
  );

  %if &lts_ttlcnt = 0 %then %do;
    %put ERROR: Life test has not been initialized.;
    %lifetestreset();
    %return;
  %end;

  data _lifetest_final_;
    set tab1-tab&lts_ttlcnt;
    if rwtype = 1 then varstr = '   ' || strip(varstr);
    else if rwtype = 2 then varstr = '      ' || strip(varstr);
  run;

  %if &lts_colcnt = 1 %then %let pvalue = 0;
  %do i = 1 %to &lts_colcnt;
    %let sttlab&i = %sysfunc(strip(&&sttlab&i));
    %let sttcnt&i = %sysfunc(strip(&&sttcnt&i));
  %end;

  %let hcolsize = 20; %* 1st column size;
  %let ncolsize = 5; %* N column size;
  %let ecolsize = 15; %* Estimates column size;

  %* p-value column size;
  %if &pvalue = 1 %then %let pcolsize = 10;
  %else %if &pvalue = 0 %then %let pcolsize = 0;

  %* Dynamic line size;
  %let linesize = %eval(4 + &hcolsize + &lts_colcnt * (&ncolsize + &ecolsize + 4) + &pcolsize);
  %if &linesize > 256 %then %let linesize = max;
  %else %if &linesize < 64 %then %let linesize = 64;
  %let save_options = %sysfunc(getoption(number)) %sysfunc(getoption(date)) %sysfunc(getoption(linesize, keyword));

  options ls = &linesize nodate nonumber;
  ods escapechar = '\';
  ods rtf file = "&outdata..rtf" style = &style bodytitle;

  title &rtftitle;
  proc report data = _lifetest_final_ nowd split = '|' style(report) = [outputwidth = 100%];
    column rwtype varstr
    %do i = 1 %to &lts_colcnt;
      ("&&sttlab&i (N = &&sttcnt&i)" &&sttvar&i..atrisk &&sttvar&i)
    %end;
    %if &pvalue %then pvalue;;

    define rwtype / display noprint;
    define varstr / 'Outcomes' style = [just = left] width = &hcolsize;
    %do i = 1 %to &lts_colcnt;
      define &&sttvar&i..atrisk / 'N' style = [just = right] width = &ncolsize;
      define &&sttvar&i / 'Prob (95% CI)' style = [just = right] width = &ecolsize;
    %end;
    %if &pvalue %then define pvalue / 'P Value' style = [just = right] width = &pcolsize;;

    compute varstr;
      if rwtype = 0 then call define(_col_, 'style/merge', 'style = []');
      else if rwtype = 1 then call define(_col_, 'style/merge', 'style = [leftmargin = 24pt]');
      else if rwtype = 2 then call define(_col_, 'style/merge', 'style = [leftmargin = 48pt]');
      else if rwtype = 9 then do;
        call define(_col_, 'style/merge', 'style = [font_weight = bold just = center]');
        call define(_row_, 'style/merge', 'style = [borderbottomstyle = solid borderbottomwidth = 1pt]');
      end;
    endcomp;
  run;

  ods rtf close;
  options &save_options;
  title;

  proc datasets lib = work nolist;
    delete tab1-tab&lts_ttlcnt;
  quit;

  %lifetestreset(); %* Reset;
%mend lifetestexport;

%macro multiztest(indata =, mean =, std =, timelist =);
  proc iml;
    use &indata where(&std > 0);
    read all var {&timelist};
    close &indata;
    bytime = unique(&timelist);
    do t = 1 to ncol(bytime);
      bythistime = bytime[t];
      use &indata where(&std > 0 & &timelist = bythistime);
      read all var {&mean &std};
      close &indata;
      nsample = nrow(&mean); %* Number of samples;
      if nsample <= 1 then do; %* Single sample;
        out = j(1, 4);
        out[1] = bythistime; out[2] = .; out[3] = 0; out[4] = .;
      end;
      else do;
        p1 = &mean[1 : (nsample - 1)];
        p2 = &mean[2 : nsample];
        x = p1 - p2;
        var = &std ## 2;
        sigma = j(nsample - 1, nsample - 1, 0); %* Init var matrix;
        do i = 1 to (nsample - 1);
          sigma[i, i] = var[i] + var[i + 1];
        end;
        do i = 1 to (nsample - 2);
          sigma[i, i + 1] = -var[i + 1];
          sigma[i + 1, i] = sigma[i, i + 1];
        end;
        chisq = t(x) * inv(sigma) * x;
        df = nsample - 1;
        p = 1 - probchi(chisq, df);
        out = bythistime || chisq || df || p;
      end;
      varname = {&timelist chisq df p};
      if t = 1 then create _pointwise_p_ from out[colname = varname];
      else edit _pointwise_p_ var varname;
      append from out;
      close _pointwise_p_;
    end;
  quit;
%mend;
