OPTIONS NOdate ls=132 ps=199;
TITLE1 "Zero-Inflated and Zero-Truncated Examples";

PROC FORMAT;
  VALUE nm 0='0' 1='1' 2='2' 3='3' 4='4' 5-6='5-6' 7-10='7-10' 11-high='GE 11';
  VALUE ysn 0='2 No' 1='1 Yes';
  VALUE gnd 0='2 Male' 1='1 Female';
run;

/*
long97data available:
https://documentation.sas.com/?docsetId=etsug&docsetTarget=etsug_countreg_examples06.htm&docsetVersion=15.1&locale=en
The COUNTREG PROCEDURE
Example 11.2 ZIP and ZINB Models for Data That Exhibit Extra Zeros
*/

* add labels;
DATA long97data;
  SET long97data;
  LABEL art='Articles published in last 3 yrs'
    fem='Female?'
    ment='Articles by Mentor';
  id+1;
RUN;

proc print data=long97data(obs=15) NOobs label;
run;

PROC FREQ DATA=long97data;
  TABLE art / NOCUM;
run;

PROC plot DATA=long97data;
  plot art * ment;
  options ls=100 ps=50;
run;

quit;

options ls=132 ps=99;

* macros for ZI log-likelihood equations;
%MACRO zipss;
  py0= EXP(-mu);
  IF y = 0 THEN
    lglk = LOG(p_zr + (1-p_zr)*py0 );
  ELSE lglk = LOG(1-p_zr) + y*LOG(mu) - mu - LGAMMA(y+1);
%MEND;

%MACRO zinb1;
  py0 = (1+k)**(-(mu/k));
  IF y = 0 THEN
    lglk = LOG( p_zr + (1-p_zr)*py0 );
  ELSE lglk = LOG(1-p_zr) + y*log(k) - (y+(mu/k))*log(1+k) + lgamma(y+(mu/k)) - lgamma(mu/k) - lgamma(y+1);
%MEND;

%MACRO zinb2;
  py0 = (1+(k*mu))**(-1/k);
  IF y = 0 THEN
    lglk = LOG( p_zr + (1-p_zr)*py0 );
  ELSE lglk = LOG(1-p_zr) + y*LOG(k*mu) - (y+(1/k))*LOG(1+(k*mu)) + lgamma(y+(1/k)) - lgamma(1/k) - lgamma(y+1);
%MEND;

%MACRO zinbp;
  pm = (1/k)*(mu**Q);
  py0 = EXP( pm*LOG( pm /(pm + mu)));
  IF y = 0 THEN
    lglk = LOG( p_zr + (1-p_zr)*py0 );
  ELSE lglk = LOG(1-p_zr)
    + ( pm*log( pm / (pm+mu))) + (y*log(1 - (pm /
    (pm+mu))))
    + (lgamma(y + pm ) - lgamma(pm) - lgamma(y+1));
%MEND;

%MACRO ziugp;
  py0 = EXP(-mu);
  IF y = 0 THEN
    lglk = LOG( p_zr + (1-p_zr)*py0 );
  ELSE lglk = LOG(1-p_zr) + log(mu) + (y-1)*log(mu + (phi*y)) - (mu + (phi*y)) - lgamma(y+1);
%MEND;

%MACRO zirgp;
  py0 = EXP( -mu/(1 + (alpha*mu)) );
  IF y = 0 THEN
    lglk = LOG( p_zr + (1-p_zr)*py0 );
  ELSE lglk = LOG(1-p_zr) + y*log(mu/(1 + (alpha*mu)))
    + (y-1)*log(1+(alpha*y))
    + ((-mu*(1+(alpha*y)))/(1+(alpha*mu))) -
    lgamma(y+1);
%MEND;

%MACRO zipig;
  py0 = EXP( (1/tau)*(1 - SQRT(1 + (2*tau*mu))) );
  IF y = 0 then
    py = py0;
  py1 = py0 * mu * (1/SQRT(1 + (2*tau*mu)));
  IF y EQ 1 then
    py = py1;
  pm1 = py1;
  pm2 = py0;

  * store f(Y=1 and f(Y=0);
  IF y GE 2 then
    DO;
      DO k = 2 to y;
        py = ((2*tau*mu/(1+ (2*tau*mu))) * (1 - (3/(2*k))) * pm1 )
          + ((mu**2)/(1 + (2*tau*mu))) * (1/(k*(k-1))) * pm2;
        pm2=pm1;
        pm1=py;
      END;
    END;
  IF y = 0 THEN
    lglk = LOG( p_zr + (1-p_zr)*py0 );
  ELSE lglk = LOG(1-p_zr) + LOG(py);
%MEND;

* run ZI models, compare Poisson and NB-2 with GENMOD;
ods select parameterestimates ZeroParameterEstimates modelfit;

PROC GENMOD DATA=long97data;
  *MODEL art = ment / dist=zip;
  * zero-inflated Poisson;
  MODEL art = ment / dist=ziNB;

  * zero-inflated negative binomial;
  ZEROMODEL ment / link = logit;
run;

%MACRO zimdls;
  ods select fitstatistics
    %IF &_mn EQ 4 %THEN %DO;
  additionalestimates
  %END;
  ;
  ods output parameterestimates=ziprms;

  PROC NLMIXED DATA=long97data(rename=(art=y));
    PARMS b0 .1 b1 .1 &prms.
      bP0 .1 bP1 .1;
    etazr = bP0 + bP1*ment;
    p_zr = 1/(1+exp(-etaZR));
    etaN = b0 + b1*ment;
    mu = exp(etaN);
    %IF &_mn EQ 1 %THEN
      %DO;
        %zipss;
      %END;
    %IF &_mn EQ 2 %THEN
      %DO;
        %zinb1;
      %END;
    %IF &_mn EQ 3 %THEN
      %DO;
        %zinb2;
      %END;
    %IF &_mn EQ 4 %THEN
      %DO;
        %zinbp;
      %END;
    %IF &_mn EQ 5 %THEN
      %DO;
        %ziugp;
      %END;
    %IF &_mn EQ 6 %THEN
      %DO;
        %zirgp;
      %END;
    %IF &_mn EQ 7 %THEN
      %DO;
        %zipig;
      %END;
    MODEL y ~ general(lglk);
    %IF &_mn EQ 4 %THEN
      %DO;
        ESTIMATE 'P= ' 2-Q;
      %END;
  run;

  Proc print data=ziprms NOObs;
    title2 'Parameter Estimates';
  run;

  PROC DATASETS NOLIST;
    DELETE ziprms;
  run;

  quit;

%MEND;

* the macro variable prms contains the initial estimates for the
dispersion parameters;

* ZI Pois;
%Let _mn=1;
%Let prms=;
TITLE "Zero-Inflated Poisson";

%zimdls;

* ZI NB-1;
%Let _mn=2;
%Let prms=k .1;
TITLE "Zero-Inflated NB-1";

%zimdls;

* ZI NB-2;
%Let _mn=3;
%Let prms=k .1;
TITLE "Zero-Inflated NB-2";

%zimdls;

* ZI NB-P;
%Let _mn=4;
%Let prms=k .1 Q 1.5;
TITLE "Zero-Inflated NB-P";

%zimdls;

* ZI UGP;
%Let _mn=5;
%Let prms=phi .1;
TITLE "Zero-Inflated Unrestr Gen Poisson";

%zimdls;

* ZI RGP;
%Let _mn=6;
%Let prms=alpha .1;
TITLE "Zero-Inflated Restricted Gen Poisson";

%zimdls;

* ZI P-IG;
%Let _mn=7;
%Let prms=tau .1;
TITLE "Zero-Inflated Poisson-Inverse Gaussian";

%zimdls;

* test truncated distributions;
* Macros for truncated log-likelihood equations;
%MACRO tpss;
  py0 = EXP(-mu);
  lglk = y*LOG(mu) - mu - lgamma(y+1)
    - LOG(1 - py0);
%MEND;

%MACRO tnb1;
  py0 = (1+k)**(-mu/k);
  lglk = (y*log(k) - (y+(mu/k))*log(1+k)
    + lgamma(y+(mu/k)) - lgamma(mu/k) - lgamma(y+1) )
    - LOG(1-py0);
%MEND;

%MACRO tnb2;
  py0 = (1 + (k*mu))**(-1/k);
  lglk = (y*log(k*mu) - (y+(1/k))*log(1+(k*mu))
    + lgamma(y+(1/k)) - lgamma(1/k) - lgamma(y+1) )
    - log(1 - py0);
%MEND;

%MACRO tnbp;
  pm = (1/k)*(mu**Q);
  py0 = EXP( pm*LOG( pm /(pm + mu)));
  lglk = ( pm *log( pm / ( pm + mu))) + (y*log(1 - ( pm / ( pm + mu))))
    + (lgamma(y + pm) - lgamma(pm) - lgamma(y+1))
    - LOG( 1 - py0);
%MEND;

%MACRO tugp;
  py0 = EXP(-mu);
  lglk = (LOG(mu) + (y-1)*log(mu + (phi*y)) - (mu + (phi*y))-lgamma(y+1) )
    - LOG(1 - py0);
%MEND;

%MACRO trgp;
  py0 = EXP( -mu/(1+(alpha*mu)) );
  lglk = (y*log(mu/(1 + (alpha*mu))) + (y-1)*log(1+(alpha*y)) + ((-
    mu*(1+(alpha*y))) /
    (1 + (alpha*mu))) - lgamma(y+1) )
    - LOG(1 - py0);
%MEND;

%MACRO tpig;
  py0 = EXP( (1/tau)*(1 - SQRT(1 + (2*tau*mu))) );
  IF y = 0 then
    py = py0;
  py1 = py0 * mu * (1/SQRT(1 + (2*tau*mu)));
  IF y EQ 1 then
    py = py1;
  pm1 = py1;
  pm2 = py0;

  * store f(Y=1 and f(Y=0);
  IF y GE 2 then
    DO;
      DO k = 2 to y;
        py = ((2*tau*mu/(1+ (2*tau*mu))) * (1 - (3/(2*k))) * pm1 )
          + ((mu**2)/(1 + (2*tau*mu))) * (1/(k*(k-1))) * pm2;
        pm2=pm1;
        pm1=py;
      END;
    END;
  pTy = py / (1-py0);
  lglk = log(pTy);
%MEND;

proc freq data=long97data;
  where art ge 1;

  table art*fem / norow nocol nopercent;
run;

ods select parameterestimates fitstatistics;

proc fmm data=long97data;
  WHERE art ge 1;

  *MODEL art = ment / dist=tpoisson;
  * zero-truncated Poisson;
  MODEL art = ment / dist=truncnegbin;

  * zero-trncated negative binomial;
run;

%macro tmdls;
  ods select fitstatistics
    %IF &_mn EQ 4 %THEN %DO;
  additionalestimates
  %END;
  ;
  ods output parameterestimates=tprms;

  PROC NLMIXED DATA=long97data(rename=(art=y));
    WHERE y GE 1;
    PARMS b0 .1 b1 .1 &prms.;
    etaN = b0 + b1*ment;
    mu = exp(etaN);
    %IF &_mn EQ 1 %THEN
      %DO;
        %tpss;
      %END;
    %IF &_mn EQ 2 %THEN
      %DO;
        %tnb1;
      %END;
    %IF &_mn EQ 3 %THEN
      %DO;
        %tnb2;
      %END;
    %IF &_mn EQ 4 %THEN
      %DO;
        %tnbp;
      %END;
    %IF &_mn EQ 5 %THEN
      %DO;
        %tugp;
      %END;
    %IF &_mn EQ 6 %THEN
      %DO;
        %trgp;
      %END;
    %IF &_mn EQ 7 %THEN
      %DO;
        %tpig;
      %END;
    MODEL y ~ general(lglk);
    %IF &_mn EQ 4 %THEN
      %DO;
        ESTIMATE 'P= ' 2-Q;
      %END;
  RUN;

  Proc print data=tprms NOObs;
    title2 'Parameter Estimates';
  run;

  PROC DATASETS NOLIST;
    DELETE tprms;
  run;

  quit;

%MEND;

* the macro variable prms contains the initial estimates for the
dispersion parameters;

* Tr Pois;
%Let _mn = 1;
%Let prms=;
title "Truncated Poisson";

%tmdls;

* Tr NB-1;
%Let _mn = 2;
%Let prms= k .1;
title "Truncated NB-1";

%tmdls;

* Tr NB-2;
%Let _mn = 3;
%Let prms= k .1;
title "Truncated NB-2";

%tmdls;

* Tr NB-P;
%Let _mn = 4;
%Let prms= k .1 Q 1.5;
title "Truncated NB-P";

%tmdls;

* Tr UGP;
%Let _mn = 5;
%Let prms= phi .1;
title "Truncated Unrestr Gen Poisson";

%tmdls;

* Tr RGP;
%Let _mn = 6;
%Let prms= alpha .1;
title "Truncated Restricted Gen Poisson";

%tmdls;

* Tr P-IG;
%Let _mn = 7;
%Let prms= tau .1;
TITLE "Truncated Poisson-Inverse Gaussian";

%tmdls;