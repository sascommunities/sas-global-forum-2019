* make a data plot showing values and missing observatios (red) with no categorical divisions;

* The MI Procedure, Example 77.6 FCS Methods for Continuous Variables, accessed March 5, 2019
https://documentation.sas.com/?docsetId=statug&docsetTarget=statug_mi_examples06.htm&docsetVersion=14.3&locale=en;
DATA Fitness1;
  INPUT Oxygen RunTime RunPulse @@;
  obs+1;
  DATALINES;
44.609 11.37 178 45.313 10.07 185
54.297 8.65 156 59.571 . .
49.874 9.22 . 44.811 11.63 176
. 11.95 176 . 10.85 .
39.442 13.08 174 60.055 8.63 170
50.541 . . 37.388 14.03 186
44.754 11.12 176 47.273 . .
51.855 10.33 166 49.156 8.95 180
40.836 10.95 168 46.672 10.00 .
46.774 10.25 . 50.388 10.08 168
39.407 12.63 174 46.080 11.17 156
45.441 9.63 164 . 8.92 .
45.118 11.08 . 39.203 12.88 168
45.790 10.47 186 50.545 9.93 148
48.673 9.40 186 47.920 11.50 170
47.467 10.50 170
;

proc sort data=fitness1;
  by descending obs;

proc print data=fitness1 n NOObs;
  var obs oxygen runtime runpulse;
run;

PROC TABULATE DATA=fitness1 noseps;
  VAR Oxygen RunTime RunPulse;

  TABLE Oxygen RunTime RunPulse, (n nmiss)*f=5.0 (min q1 median q3 max)*f=6.1 / rts=12;
RUN;

* several MACRO variables included to make editing easier;
%LET pth = u:\sas\missing\plots;

* path to store graph;
%LET nmg = fitnss1;

* name of graph;
%LET hgt = 2.5;

* graph height;
%LET wdt = 4;

* graph width;
%LET dsn = fitness1;

* dataset;
%LET nrank = 6;

* number of color shades for existing data;

* required: enter numeric variable names:
at least one variable must have one or more missing values;
%LET mssVr = Oxygen RunTime RunPulse;

* optional: enter one variable with no missing data or a sorting variable (column 1);
%LET nvr = obs;
%LET txtsize = 4;

* counts and percents at top of graph;
%LET rwa = 97;

* location of the rows for counts and percents;
%LET rwb = 93;

* Missing data pattern format ( - = value exists, m=missing);
PROC FORMAT;
  VALUE mssp 1-&nrank. ='-' %EVAL(&nrank. + 1) ='m';
run;

* place variable with no missing data first and list on macro below;
%LET nvrlst = &nvr &mssVr;

* all numeric variable names;
%PUT &nvrlst;
%LET nvrs = %sysfunc(countw(&nvrlst.));

* count the number of numeric variables;
%PUT &nvrs;

* add extra space horizontally next to y and y2 axes, depending on number of variables;
%LET offst=.18;
%LET yoffstmx = %SYSEVALF( (100 - &rwb.)/100 + .02 );

* percent from border to top of data plot;
PROC SORT DATA=&dsn.;
  by &nvrlst.;
RUN;

* number of observations in data set into a macro var;
DATA _null_;
  SET &dsn. nobs=nnn;
  call symputx("nn",nnn);
  STOP;
run;

%PUT &nn;

* collect counts and percents of missing data;
ODS OUTPUT misspattern=_msptrn
  univariate=_unv(KEEP = variable NMiss PctMiss);

*ODS LISTING close;
PROC MI data=&dsn. nimpute=0 simple;
  VAR &nvrlst.;
RUN;

ods listing;

proc print data=_msptrn(drop=&nvrlst ) NOObs n;
  format _numeric_ 5.0 percent 5.1;
run;

* ordr: entered to retain the original order of observations;
data _unv;
  set _unv;
  ordr+1;

  *proc print data=_unv;
run;

proc transpose data=_unv out=_tunv1(drop=_name_ _label_ ) prefix=_n;
  var nmiss;
  id ordr;

  /*proc print data=_tunv1 noobs; title 'counts'; run;*/
proc transpose data=_unv out=_tunv2(drop=_name_ _label_ ) prefix=_p;
  var pctmiss;
  id ordr;

  /*proc print data=_tunv2 noobs; title 'percents'; run;*/
RUN;

* labels with number and percent of missing values to annotate the plot;
DATA _ms;
  SET _tunv1;
  set _tunv2;
  DROP _n1-_n&nvrs. _p1-_p&nvrs. i;
  array nms{&nvrs.} $8 _nms1 - _nms&nvrs.;

  * number;
  array msp{&nvrs.} $11 _msp1 - _msp&nvrs.;

  * percent;
  array nn{&nvrs.} _n1-_n&nvrs.;

  * number;
  array pp{&nvrs.} _p1-_p&nvrs.;

  * percent;
  do i = 1 to &nvrs.;
    if nn{i} = . then
      nn{i} = 0;
    nms{i} = cat(strip(put(nn{i},3.0)));
    if pp{i} = . then
      pp{i} = 0;
    msp{i} = cat(strip(put(pp{i},5.1)),'%');
  end;

proc print DATA=_ms Noobs;
run;

DATA _nnA;
  SET _ms(in=jj);
  DROP _msp: _nms:;
  array nms{&nvrs.} $17 _nms1 - _nms&nvrs.;
  array msp{&nvrs.} $17 _msp1 - _msp&nvrs.;
  if jj then
    DO;
      function = "text";
      textcolor= 'black';
      textsize = &txtsize.;
      textweight = 'bold';
      width = 12;
      y1space = "wallpercent";
      x1space = "datavalue";
      y1 = &rwa.;
      DO x1= 1 to &nvrs.;
        label=nms{x1};
        OUTPUT;
      END;

      * print counts and percents;
      y1 = &rwb.;
      DO x1= 1 to &nvrs.;
        label=msp{x1};
        OUTPUT;
      END;

      * in white space at top of plot;
    END;

PROC PRINT data=_nnA NOObs;
RUN;

* format to print variable names on horizontal axis;
DATA _Rfmt;
  LENGTH label $15;
  RETAIN fmtname "_vrr" type 'N';
  DO start = 1 TO &nvrs.;
    label = scan("&nvrlst",start,' ');
    output;
  END;

  *proc print NOObs;
RUN;

proc format cntlin=_Rfmt;
run;

PROC RANK DATA=&dsn. out=_1b groups=&nrank.;
  VAR &nvrlst.;
  RANKS _i1 - _i&nvrs.;
run;

DATA _1b;
  SET _1b;
  DROP i;
  LENGTH pttrn $&nvrs.;
  ARRAY gp{&nvrs.} _i1 - _i&nvrs.;
  DO i = 1 to &nvrs.;
    gp{i} = gp{i} + 1;

    * ranks start at 0, need to start at 1;
    IF gp{i} = . then
      gp{i} = &nrank. + 1;

    * the number of ranks plus 1 (rank +1) displays missing data;
  END;
  DO i = 1 to &nvrs.;
    pttrn= cats(pttrn,put(gp{i},mssp.));
  END;
RUN;

proc print data=_1b(obs=6);
run;

* obsvno for plotting on vertical axis of graph;
proc sort data=_1b;
  by _i1 &nvR. &mssVr.;
run;

DATA _1b;
  SET _1b;
  obsvno+1;
RUN;

proc print data=_1b(obs=12) NOObs;
  ID &nVr. _i1 - _i&nvrs. obsvno;
run;

DATA _2b;
  SET _1b(drop=pttrn);
  ARRAY val{&nvrs.} &nvrlst.;
  ARRAY grR{&nvrs.} _i1 - _i&nvrs.;
  KEEP obsvno _i1 - _i&nvrs. i xv xvL xvu rank &nvr.;
  DO i = 1 to &nvrs.;
    xv = i;
    xvL=xv - .48;
    xvU = xv + .48;

    * adjustment to coordinates of line plotted on graph;
    y=val{i};
    rank=grR{i};
    OUTPUT;
  END;

proc sort data=_2b;
  by xv rank obsvno;

proc print DATA=_2b(obs=12);
run;

PROC FREQ DATA=_2b;
  TABLE xv * rank / norow nocol nopercent;
    format xv vrr.;
run;

* method 1: SCATTER statement;
* the datalinepatterns() option does not work with errorbarattrs=();
ods graphics on / reset = all height=&hgt. in width=&wdt. in border= off ANTIALIASMAX=8500;
ods listing image_dpi=200 gpath="&pth";
ods graphics / imagename = "&nmg";

PROC SGPLOT DATA=_2b noautolegend sganno=_nnA;
  STYLEATTRS DATACONTRASTCOLORS=( Grayd9 Graybd Gray96 Gray73 Gray52 Gray25 CXE31A1C);

  /* 6 shades of gray with bright red for missing*/
  SCATTER x=xv y=obsvno / group=rank GROUPORDER=ascending
    xerrorlower=xvL xerrorupper=xvU
    errorbarattrs=(pattern=solid thickness=1)
    NOERRORCAPS /*ERRORCAPSCALE=0.01 */
  markerattrs=(size=0);
  YAXIS offsetmin=.025 offsetmax=&yoffstmx. min=1 max=&nn.
  values=(1 to &nn. by 1) display=(nolabel noticks novalues);
  XAXIS offsetmin=&offst. offsetmax=&offst. values =(1 to &nvrs. by 1)
    valueattrs=(weight=bold size=5) display=(nolabel);
  FORMAT xv _vrr.;
  TITLE1 "Missing Data Patterns (N=&nn, &nrank ranked groups)";
run;

ODS GRAPHICS off;

* method 2: HIGHLOW statement;
ods graphics on / reset = all height=&hgt. in width=&wdt. In
  border= off ANTIALIASMAX=8500;
ods listing image_dpi=200 gpath="&pth";
ods graphics / imagename = "&nmg._v2";

PROC SGPLOT DATA=_2b noautolegend sganno=_nnA;
  STYLEATTRS
    DATACONTRASTCOLORS=( Grayd9 Graybd Gray96 Gray73 Gray52 Gray25 CXE31A1C)
    datalinepatterns =( solid solid solid solid solid solid mediumdash);
  HIGHLOW y=obsvno high=xvU low=xvL / group=rank type=line
    lineattrs=(thickness=1);
  YAXIS offsetmin=.025 offsetmax=&yoffstmx. min=1 max=&nn.
    values=(1 to &nn. by 1) display=(nolabel noticks novalues);
  XAXIS offsetmin=&offst. offsetmax=&offst. values =(1 to &nvrs. by 1)
    valueattrs=(weight=bold size=5) display=(nolabel);
  FORMAT xvU xvL _vrr.;
  TITLE1 "Missing Data Patterns (N=&nn, &nrank ranked groups)";
run;

ODS GRAPHICS off;

proc freq data=_1b;
  table pttrn / noprint out=_pttrn;
run;

proc sort;
  by descending count pttrn;

DATA _pttrn;
  SET _pttrn;
  group+1;
RUN;

/*
proc print data=_pttrn NOObs;
where count GE 2;
title 'Patterns of missing data';
run;
*/
DATA _null_;
  LENGTH tmp $ &nvrs.;
  DO i = 1 to &nvrs.;
    j= mod(i,10);
    tmp = cats(tmp,put(j,1.0));
  end;
  call symputx("nv",tmp);
  put tmp;
  mx = max((2*(&nvrs.+1)+1), 20);
  call symputx("mxr",mx);
run;

%PUT &nv &mxr;

/*proc print data=&dsn.(obs=1); var &nvrlst.; run;*/
DATA _varlist;
  SET &dsn.(obs=1 keep=&nvrlst.);
  LENGTH _nm_ $15 _name_ $18;
  KEEP _name_;
  ARRAY nmr{*} &nvrlst.;
  DO ordr = 1 to dim(nmr);
    _nm_ = lowcase(vname(nmr{ordr}));
    _name_ = cats(put(ordr,2.0),'=',strip(lowcase(_nm_)));
    output;
  end;

  *proc print;
run;

proc sql noprint;
  select _name_ into :vrlst separated by ' ' from _varlist;
quit;

%put &vrlst;

PROC TABULATE DATA= _pttrn noseps;
  CLASS group pttrn / order=data;

  TABLE group *pttrn="&nv" all='Total', (n='N'*f=6.0 colpctN='Percent'*f=7.1 ) / rts=%EVAL(&mxr.+1) misstext=' ' box='m=Missing';
    FREQ count;
    TITLE1 "Missing Data Patterns";
    TITLE2 "&vrlst";
RUN;

* Delete temporary files;
PROC DATASETS NOLIST;
  DELETE _Rfmt _1b _2b _pttrn _nnA _varlist _tunv1 _tunv2 _ms;
RUN;

QUIT;

/*
 * baseball data;
data bsbll;
set sashelp.baseball;
keep nHits nRBI nHome YrMajor nAssts nAtBat nBB nError nOuts nRuns Salary ;
run;
%LET pth = u:\sas\missing\plots; * path of graph;
%LET nmg = bsbll; * name of graph;
%LET hgt = 8; * graph height;
%LET wdt = 6; * graph width;
%LET dsn = bsbll; * dataset;
%LET nrank = 6; * number of color shades for existing data;
%LET mssVr = nrbi nruns nHome nAtBat nBB nOuts Salary ; * variable names: at least one variable with missing values (required);
%LET nvr = nhits ; * one variable(s) with no missing data (not required) or sorting variable;
PROC TABULATE DATA=bsbll noseps;
VAR &nvr &mssVr;
TABLE &nvr &mssVr, (n nmiss)*f=5.0 (min q1 median q3 max)*f=6.1 / rts=22;
RUN;
%LET txtsize = 6 ;
%LET rwa = 98;
%LET rwb = 95;
*/