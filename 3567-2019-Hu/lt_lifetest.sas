/* Macro function for conducting survival analysis for left truncated data
/* Maintainer: Zhen-Huan Hu <zhu@mcw.edu>
/* Last change: 2018-03-19
/*
/* -------------------------------------------- */
/* Functions and their basic uses:
/*
/* %lt_lifetest(indata =, outdata = _output_, strata = , event =, intv =, ltime =, timelist =, noprint = 0);
/*
/* INDATA:	  Name of the input data set
/* OUTDATA:       Name of the output data set (optional)
/* STRATA:	  Main group
/* EVENT:	  Event of interest (default: dead)
/* INTV:	  Time to the event / right censoring
/* LTIME:         Left truncation time
/* TIMELIST:	  Specific time points for survival estimates
/* NOPRINT:       Toggle whether print the results (default: 0)
/* -------------------------------------------- */

%macro lt_lifetest(indata =, outdata = _output_, strata = , event =, intv =, ltime =, timelist =, noprint = 0);
  %* Get format;
  %let dsid = %sysfunc(open(&indata, i));
  %let lt_stt_num = %sysfunc(varnum(&dsid, &strata));
  %let lt_stt_fmt = %sysfunc(varfmt(&dsid, &lt_stt_num));
  %let lt_rc = %sysfunc(close(&dsid));

  %* Calculate KM est;
  proc iml;
    use &indata;
    read all var {&strata &event &intv &ltime};
    close &indata;
    rblock = {};
    timelist = {&timelist};
    if ncol(timelist) > 1 then timelist = t(timelist);
    bystrata = unique(&strata);
    ns = ncol(bystrata);
    do s = 1 to ns;
      cur_loc = loc(&strata = bystrata[s]);
      cur_time = t(unique(&intv[cur_loc] // timelist));
      call sort(cur_time);
      nt = nrow(cur_time);
      natrisk = j(nt, 1, .);
      nevents = j(nt, 1, .);
      do t = 1 to nt;
        natrisk[t] = ncol(loc(&ltime[cur_loc] < cur_time[t] & cur_time[t] <= &intv[cur_loc]));
        nevents[t] = ncol(loc(&event[cur_loc] = 1 & &intv[cur_loc] = cur_time[t]));
      end;
      surv = j(nt, 1, .);
      fail = j(nt, 1, .);
      loc_surv = loc(natrisk > 0);
      surv[loc_surv] = cuprod(1 - nevents[loc_surv] / natrisk[loc_surv]);
      fail[loc_surv] = 1 - surv[loc_surv];
      stderr = j(nt, 1, .);
      loc_stderr = loc(natrisk > 0 & (natrisk - nevents > 0));
      stderr[loc_stderr] = surv[loc_stderr] # sqrt(cusum(nevents[loc_stderr] / (natrisk # (natrisk - nevents))[loc_stderr]));
      cur_rblock = j(nt, 1, bystrata[s]) || cur_time || surv || fail || stderr || natrisk || nevents;
      rblock = rblock // cur_rblock;
    end;
    create _lt_output_ from rblock[colname = {&strata &intv survival failure stderr numberatrisk observedevents}];
    append from rblock;
    close _lt_output_;
  quit;

  data &outdata;
    set _lt_output_;
    %if %sysfunc(countw(&timelist, %str( ))) > 0 %then %do;
      where &intv in (&timelist);
      rename &intv = timelist;
      drop observedevents;
    %end;
    format &strata &lt_stt_fmt;
  run;

  %if &noprint = 0 %then %do;
    title "Survival Probabilities";    
    proc sort data = &outdata; by &strata;
    proc print data = &outdata noobs width = min;
      by &strata;
    run;
    title;
  %end;
%mend;
