/*When importing the BRFSS data, you have the option of using the formats
If so, replace the "dataout" library information with the location of
your formats and the sasdata file that the pre-created syntax makes*/
options FMTSEARCH=(dataout);
/*Because we made persdoc2 a two level variable, we re-made the format*/
proc format ;
value pers 
1 = "At Least One Doc"
3 = "No Doc";
run;
/*Syntax to clean the original BRFSS 2017 data set and create a
practice data set for the five examples in the paper*/
data brfss2;
set dataout.sasdata;
keep _age_g sex wtkg3 persdoc2 _rfbmi5 cvdcrhd4 _race_g1
_psu _STSTR _LLCPWT;
wtkg3 = wtkg3*.01;
if sex = 9 then sex = .;
if persdoc2 in (7,9) then persdoc2 = .;
if persdoc2 in (1,2) then persdoc2 = 1;
if _rfbmi5 = 9 then _rfbmi5 = .;
if cvdcrhd4 in (7,9) then cvdcrhd4 = .;
label persdoc2 = "At Least One Doctor";
format persdoc2 pers.;
run;

/*Example 1*/

proc freq data = brfss2;
tables _rfbmi5 cvdcrhd4 persdoc2;
weight _llcpwt;
run;

proc surveyfreq data = brfss2;
cluster _psu;
strata _ststr;
weight _llcpwt;
tables _rfbmi5 cvdcrhd4 persdoc2;
run;

/*Example 2*/
proc surveyfreq data = brfss2;
cluster _psu;
strata _ststr;
weight _llcpwt;
tables persdoc2*cvdcrhd4 / or;
run;

proc surveylogistic data = brfss2;
cluster _psu;
strata _ststr;
weight _llcpwt;
class persdoc2 (ref='No Doc');
model cvdcrhd4 (event='Yes')= persdoc2;
run;

/*Example 3*/

proc surveyfreq data = brfss2;
cluster _psu;
strata _ststr;
weight _llcpwt;
tables _rfbmi5*persdoc2*cvdcrhd4 / or;
run;

proc surveylogistic data = brfss2;
domain _rfbmi5;
cluster _psu;
strata _ststr;
weight _llcpwt;
class persdoc2 (ref='No Doc');
model cvdcrhd4 (event='Yes')= persdoc2;
run;

/*Example 4*/

proc surveylogistic data = brfss2;
cluster _psu;
strata _ststr;
weight _llcpwt;
class persdoc2 (ref='No Doc') _rfbmi5 (ref='Yes');
model cvdcrhd4 (event='Yes')= persdoc2 _rfbmi5 persdoc2*_rfbmi5;
run;

/*Example 5*/
PROC SURVEYREG data = brfss2;
CLASS persdoc2 (ref='No Doc') cvdcrhd4 (ref='No');
CLUSTER _psu;
MODEL wtkg3 = persdoc2 cvdcrhd4 / solution;
STRATA _ststr;
WEIGHT _llcpwt;
RUN;
