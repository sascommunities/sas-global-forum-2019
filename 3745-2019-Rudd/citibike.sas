libname rudd '\\cdc.gov\private\L317\icj2\SAS\SASGF_symposium\Data';

/* Import csv files by month */

/*%Macro loop;
%LOCAL I;
%LET I = 201601;/* %TO 201612 %by 1; /* Update here when new datasets become available*/

/*filename bike&I '\\cdc.gov\private\L317\icj2\SAS\SASGF_symposium\Data\&I.-citibike-tripdata.csv';*/
data citibike12;
  %let _EFIERR_ = 0; /* SET THE ERROR DETECTION MACRO VARIABLE */
  infile '\\cdc.gov\private\L317\icj2\SAS\SASGF_symposium\Data\201612-citibike-tripdata.csv' delimiter = ','
    missover dsd lrecl=32767 firstobs=2;
  informat tripduration BEST32.;
  informat starttime ANYDTDTM40.;
  informat endtime ANYDTDTM40.;
  informat start_station_id BEST32.;
  informat start_station_name $29.;
  informat start_station_latitude BEST32.;
  informat start_station_longitude BEST32.;
  informat end_station_id BEST32.;
  informat end_station_name $29.;
  informat end_station_latitude BEST32.;
  informat end_station_longitude BEST32.;
  informat bikeid BEST32.;
  informat usertype $10.;
  informat birth_year BEST32.;
  informat gender BEST32.;
  format tripduration BEST12.;
  format starttime datetime.;
  format endtime datetime.;
  format start_station_id BEST12.;
  format start_station_name $29.;
  format start_station_latitude BEST12.;
  format start_station_longitude BEST12.;
  format end_station_id BEST12.;
  format end_station_name $29.;
  format end_station_latitude BEST12.;
  format end_station_longitude BEST12.;
  format bikeid BEST12.;
  format usertype $10.;
  format birth_year BEST12.;
  format gender BEST12.;
  input tripduration starttime endtime start_station_id start_station_name $
    start_station_latitude start_station_longitude end_station_id end_station_name $ end_station_latitu
    end_station_longitude bikeid usertype $ birth_year gender;
  if _ERROR_ then call symput('_EFIERR_',1); /* set ERROR detection macro variable */
run;

/*%END;
%MEND LOOP;
%LOOP;
QUIT;*/
Proc contents data=citibike01;
run;

/*Combining all months of data*/
Data allbike2016;
  set CITIBIKE01 CITIBIKE02 CITIBIKE03 CITIBIKE04 CITIBIKE05 CITIBIKE06 CITIBIKE07
    CITIBIKE08 CITIBIKE09 CITIBIKE10 CITIBIKE11 CITIBIKE12;
run;

/*Checking contents*/
Proc contents data=allbike2016;
run;

/*Checking some frequencies*/
Proc freq data=allbike2016;
  tables usertype gender;
run;

Proc univariate data=allbike2016;
  var tripduration;
  histogram;
run;

/*Create some formats*/
Proc format;
  value dow 1 = "Sunday"
    2 = "Monday"
    3 = "Tuesday"
    4 = "Wednesday"
    5 = "Thursday"
    6 = "Friday"
    7 = "Saturday";
  value mth 1 = "January"
    2 = "February"
    3 = "March"
    4 = "April"
    5 = "May"
    6 = "June"
    7 = "July"
    8 = "August"
    9 = "September"
    10 = "October"
    11 = "November"
    12 = "December";
  value gender 0 = "Unknown"
    1 = "Male"
    2 = "Female";
  value yn 0= 'No'
    1= 'Yes';
  value rush 1='AM rush hour'
    2='PM rush hour'
    0='Not rush hour';
run;

/*Creating some analysis variables*/
Data allbike2016_a;
  set allbike2016;
  age = 2016 - birth_year;
  start_date = datepart(starttime);
  start_time = timepart(starttime);
  end_date = datepart(endtime);
  end_time = timepart(endtime);
  weekday = weekday(start_date);
  month = month(start_date);
  format start_date end_date mmddyy10. start_time end_time time8. weekday dow. month mth. gender gender.;
run;

/*Check distributions of complete dataset*/
Proc freq data=allbike2016_a;
  tables weekday month gender usertype*weekday;
run;

/*Take 10% sample for use in Kennesaw SAS grid*/
Proc Surveyselect data=allbike2016_a out= allbike2016_samp method=srs samprate=0.1;
run;

/* Check distributions of sample data same as full dataset*/
Proc freq data=allbike2016_samp;
  table weekday month gender;
run;

libname bike '/gpfs/sasdata1/bikeride';

Proc contents data=bike.ntrip;
run;

/* Create hour of day var (HoD), workday( 1= yes, 0 = no), rush hour (rush, 1= am, 2 = pm, 0 = no)*/
Data bike.ntrip_new;
  set bike.ntrip;
  HoD = hour(start_time);
  if weekday in (2,3,4,5,6) then
    workday = 1;
  else workday = 0;
  if HoD in (7,8,9) and workday = 1 then
    rush = 1;
  else if HoD in (16,17,18,19) and workday =2 then
    rush = 2;
  else rush = 0;
run;

*/
Take 10% subject random sample for testing */;

Proc Surveyselect data=bike.ntrip out= bike method=srs samprate=0.1;
run;

libname rudd '/gpfs/user_home/jrudd1/DataMiningI_Project';

/* Save sample in personal drive for testing purposes */
Data rudd.bike;
  set bike;
  format start_date end_date mmddyy10. start_time end_time time8. weekday dow. month mth. gender gender.;
run;

/* Create hour of day var (HoD), workday( 1= yes, 0 = no), rush hour (rush, 1= am, 2 = pm, 0 = no)*/
Data bike1;
  set bike;
  HoD = hour(start_time);
  if weekday in (2,3,4,5,6) then
    workday = 1;
  else workday = 0;
  if HoD in (7,8,9) and workday = 1 then
    rush = 1;
  else if HoD in (16,17,18,19) and workday =2 then
    rush = 2;
  else rush = 0;
run;

/* Check out distributions of nominal analysis variables */
ods noproctitle;
ods graphics / imagemap=on;

/*** Exploring Data ***/
proc univariate data=WORK.BIKE2;
  ods select Histogram;
  var no_of_trips tripduration age PRCP SNWD SNOW TMAX TMIN AWND;
  histogram no_of_trips tripduration age PRCP SNWD SNOW TMAX TMIN AWND / normal;
  inset n mean median std skewness kurtosis / position=ne;
run;

proc univariate data=WORK.BIKE2;
  ods select Histogram GoodnessOfFit ProbPlot;
  var no_of_trips tripduration age PRCP SNWD SNOW TMAX TMIN AWND;

  /*** Checking for Normality ***/
  histogram no_of_trips tripduration age PRCP SNWD SNOW TMAX TMIN AWND /
    normal(mu=est sigma=est);
  inset n / position=ne;
  probplot no_of_trips tripduration age PRCP SNWD SNOW TMAX TMIN AWND /
    normal(mu=est sigma=est);
  inset n / position=nw;
run;

/* Average trips by day of week */
/*--Set output size--*/
ods graphics / reset imagemap;

/*--SGPLOT proc statement--*/
proc sgplot data=WORK.BIKE1;
  /*--TITLE and FOOTNOTE--*/
  title 'Total Number of Trips by Day of Week (2016)';

  /*--Bar chart settings--*/
  vbar weekday / response=no_of_trips stat=Sum name='Bar';

  /*--Category Axis--*/
  xaxis label='Day of Week';

  /*--Response Axis--*/
  yaxis label='# of trips (Sum)' grid;
run;

ods graphics / reset;
title;

/* Total trips by day of week and customer status*/
/*--Sort data by BY variable--*/
proc sort data=WORK.BIKE1 out=_BarChartTaskData;
  by usertype;
run;

/*--Set output size--*/
ods graphics / reset imagemap;

/*--SGPLOT proc statement--*/
proc sgplot data=_BarChartTaskData (where=(usertype ne ' '));
  /*--BY Variable--*/
  by usertype;

  /*--TITLE and FOOTNOTE--*/
  title 'Total Number of Trips by Day of Week (2016)';

  /*--Bar chart settings--*/
  vbar weekday / response=no_of_trips stat=Sum name='Bar';

  /*--Category Axis--*/
  xaxis label='Day of Week';

  /*--Response Axis--*/
  yaxis label='# of trips (Sum)' grid;
run;

ods graphics / reset;
title;

/* Total trips by hour of day */
ods graphics / reset imagemap;

/*--SGPLOT proc statement--*/
proc sgplot data=WORK.BIKE1;
  /*--TITLE and FOOTNOTE--*/
  title 'Total Number of Trips by Hour of Day (2016)';

  /*--Bar chart settings--*/
  vbar HoD / response=no_of_trips stat=Sum name='Bar';

  /*--Category Axis--*/
  xaxis label='Hour of Day';

  /*--Response Axis--*/
  yaxis label='# of trips (Sum)' grid;
run;

ods graphics / reset;
title;

/* Total trips by hour of day and customer type */
/*--Sort data by BY variable--*/
proc sort data=WORK.BIKE1 out=_BarChartTaskData;
  by usertype;
run;

/*--Set output size--*/
ods graphics / reset imagemap;

/*--SGPLOT proc statement--*/
proc sgplot data=_BarChartTaskData (where=(usertype ne ' '));
  /*--BY Variable--*/
  by usertype;

  /*--TITLE and FOOTNOTE--*/
  title 'Total Number of Trips by Hour of Day (2016)';

  /*--Bar chart settings--*/
  vbar HoD / response=no_of_trips stat=Sum name='Bar';

  /*--Category Axis--*/
  xaxis label='Hour of Day';

  /*--Response Axis--*/
  yaxis label='# of trips (Sum)' grid;
run;

ods graphics / reset;
title;

/* Total trips by month */
/*--Set output size--*/
ods graphics / reset imagemap;

/*--SGPLOT proc statement--*/
proc sgplot data=WORK.BIKE1;
  /*--TITLE and FOOTNOTE--*/
  title 'Total Number of Trips by Month (2016)';

  /*--Bar chart settings--*/
  vbar month / response=no_of_trips stat=Sum name='Bar';

  /*--Category Axis--*/
  xaxis label='Month';

  /*--Response Axis--*/
  yaxis label='# of trips (Sum)' grid;
run;

ods graphics / reset;
title;

/* Average trips by Month and average temperature */
/*--Put statistic into macro variable--*/
%let stat=Mean;

/*--Compute axis ranges--*/
proc means data=WORK.BIKE1 noprint;
  class month / order=data;
  var no_of_trips TMAX;
  output out=_BarLine_(where=(_type_ >
    0)) mean(no_of_trips TMAX)=resp1 resp2;
  ;
run;

/*--Compute response min and max values (include 0 in computations)--*/
data _null_;
  retain respmin 0 respmax 0;
  retain respmin1 0 respmax1 0 respmin2 0 respmax2 0;
  set _BarLine_ end=last;
  respmin1=min(respmin1, resp1);
  respmin2=min(respmin2, resp2);
  respmax1=max(respmax1, resp1);
  respmax2=max(respmax2, resp2);
  if last then
    do;
      call symputx ("respmin1", respmin1);
      call symputx ("respmax1", respmax1);
      call symputx ("respmin2", respmin2);
      call symputx ("respmax2", respmax2);
      call symputx ("respmin", min(respmin1, respmin2));
      call symputx ("respmax", max(respmax1, respmax2));
    end;
run;

/*--Define a macro for offset--*/
%macro offset ();
  %if %sysevalf(&respmin eq 0) %then
    %do;
      offsetmin=0
    %end;
  %if %sysevalf(&respmax eq 0) %then
    %do;
      offsetmax=0
    %end;
%mend offset;

/*--Set output size--*/
ods graphics / reset imagemap;

/*--SGPLOT proc statement--*/
proc sgplot data=WORK.BIKE1 nocycleattrs;
  /*--TITLE and FOOTNOTE--*/
  title 'Average # of Trips by Month and Max Average Temperature (2016)';

  /*--Bar chart settings--*/
  vbar month / response=no_of_trips stat=Mean name='Bar';

  /*--Line chart settings--*/
  vline month / response=TMAX lineattrs=(thickness=5) y2axis stat=Mean
    name='Line';

  /*--Category Axis--*/
  xaxis label='Month';

  /*--Bar Response Axis--*/
  yaxis grid label='# of trips (average)' min=&respmin1 max=&respmax1
    %offset();

  /*--Line Response Axis--*/
  y2axis label='Max temperature (average)' min=&respmin2 max=&respmax2
    %offset();
run;

ods graphics / reset;
title;

/* Scatterplot of trips by max temperature */
/*--Set output size--*/
ods graphics / reset imagemap;

/*--SGPLOT proc statement--*/
proc sgplot data=WORK.BIKE2;
  /*--TITLE and FOOTNOTE--*/
  title 'Scatterplot of Max Temperature and Total Number of Trips (2016)';

  /*--Scatter plot settings--*/
  scatter x=TMAX y=no_of_trips / transparency=0.0 name='Scatter';

  /*--X Axis--*/
  xaxis grid label='Max Temperature';

  /*--Y Axis--*/
  yaxis grid label='# of Trips';
run;

ods graphics / reset;
title;

/* Average trips by Month and average precipitation*/
/*--Put statistic into macro variable--*/
%let stat=Mean;

/*--Compute axis ranges--*/
proc means data=WORK.BIKE1 noprint;
  class month / order=data;
  var no_of_trips PRCP;
  output out=_BarLine_(where=(_type_ >
    0)) mean(no_of_trips PRCP)=resp1 resp2;
  ;
run;

/*--Compute response min and max values (include 0 in computations)--*/
data _null_;
  retain respmin 0 respmax 0;
  retain respmin1 0 respmax1 0 respmin2 0 respmax2 0;
  set _BarLine_ end=last;
  respmin1=min(respmin1, resp1);
  respmin2=min(respmin2, resp2);
  respmax1=max(respmax1, resp1);
  respmax2=max(respmax2, resp2);
  if last then
    do;
      call symputx ("respmin1", respmin1);
      call symputx ("respmax1", respmax1);
      call symputx ("respmin2", respmin2);
      call symputx ("respmax2", respmax2);
      call symputx ("respmin", min(respmin1, respmin2));
      call symputx ("respmax", max(respmax1, respmax2));
    end;
run;

/*--Define a macro for offset--*/
%macro offset ();
  %if %sysevalf(&respmin eq 0) %then
    %do;
      offsetmin=0
    %end;
  %if %sysevalf(&respmax eq 0) %then
    %do;
      offsetmax=0
    %end;
%mend offset;

/*--Set output size--*/
ods graphics / reset imagemap;

/*--SGPLOT proc statement--*/
proc sgplot data=WORK.BIKE1 nocycleattrs;
  /*--TITLE and FOOTNOTE--*/
  title 'Average # of Trips by Month and Average Precipitation(2016)';

  /*--Bar chart settings--*/
  vbar month / response=no_of_trips stat=Mean name='Bar';

  /*--Line chart settings--*/
  vline month / response=PRCP lineattrs=(thickness=5) y2axis stat=Mean
    name='Line';

  /*--Category Axis--*/
  xaxis label='Month';

  /*--Bar Response Axis--*/
  yaxis grid label='# of trips (average)' min=&respmin1 max=&respmax1
    %offset();

  /*--Line Response Axis--*/
  y2axis label='Max temperature (average)' min=&respmin2 max=&respmax2
    %offset();
run;

ods graphics / reset;
title;

/* There doesn't appear to be a relationship between precipitation and trips over
the whole year, but may affect daily ridership numbers. Let's look at trips over
the whole month of July, rainiest month of the year */

/*--Put statistic into macro variable--*/
%let stat=Mean;

/*--Compute axis ranges--*/
proc means data=WORK.BIKE1
  (where=(month=7)) noprint;
  class day / order=data;
  var no_of_trips PRCP;
  output out=_BarLine_(where=(_type_ >
    0)) mean(no_of_trips PRCP)=resp1 resp2;
  ;
run;

/*--Compute response min and max values (include 0 in computations)--*/
data _null_;
  retain respmin 0 respmax 0;
  retain respmin1 0 respmax1 0 respmin2 0 respmax2 0;
  set _BarLine_ end=last;
  respmin1=min(respmin1, resp1);
  respmin2=min(respmin2, resp2);
  respmax1=max(respmax1, resp1);
  respmax2=max(respmax2, resp2);
  if last then
    do;
      call symputx ("respmin1", respmin1);
      call symputx ("respmax1", respmax1);
      call symputx ("respmin2", respmin2);
      call symputx ("respmax2", respmax2);
      call symputx ("respmin", min(respmin1, respmin2));
      call symputx ("respmax", max(respmax1, respmax2));
    end;
run;

/*--Define a macro for offset--*/
%macro offset ();
  %if %sysevalf(&respmin eq 0) %then
    %do;
      offsetmin=0
    %end;
  %if %sysevalf(&respmax eq 0) %then
    %do;
      offsetmax=0
    %end;
%mend offset;

/*--Set output size--*/
ods graphics / reset imagemap;

/*--SGPLOT proc statement--*/
proc sgplot data=WORK.BIKE1
  (where=(month=7)) nocycleattrs;
  /*--TITLE and FOOTNOTE--*/
  title 'Average # of Trips by Day and Average Precipitation(July, 2016)';

  /*--Bar chart settings--*/
  vbar day / response=no_of_trips stat=Mean name='Bar';

  /*--Line chart settings--*/
  vline day / response=PRCP lineattrs=(thickness=5) y2axis stat=Mean name='Line';

  /*--Category Axis--*/
  xaxis label='Month';

  /*--Bar Response Axis--*/
  yaxis grid label='# of trips (average)' min=&respmin1 max=&respmax1
    %offset();

  /*--Line Response Axis--*/
  y2axis label='Max temperature (average)' min=&respmin2 max=&respmax2
    %offset();
run;

ods graphics / reset;
title;

/* Look at distribution of precipitation variable */
ods noproctitle;

/*** Analyze numeric variables ***/
title "Descriptive Statistics for Numeric Variables";

proc means data=WORK.BIKE1 n nmiss min mean median max std;
  var PRCP;
run;

title;

proc univariate data=WORK.BIKE1 noprint;
  histogram PRCP;
run;

/* Bin precipitation into rain (0 = no rain, 1 = more than 0 inches)*/
Data bike2;
  set bike1;
  if prcp > 0 then
    rain = 1;
  else rain = 0;
run;

/* Look at new distribution */
Proc freq data=bike2;
  tables rain;
run;

/* Difference in trip distribution between rainy and non-rainy days? */
/*--Set output size--*/
ods graphics / reset imagemap;

/*--SGPLOT proc statement--*/
proc sgplot data=WORK.BIKE2;
  /*--TITLE and FOOTNOTE--*/
  title 'Box Plot of # of Trips by Rainy Day';

  /*--Box Plot settings--*/
  vbox no_of_trips / category=rain fillattrs=(color=CXcad5e5) name='Box';

  /*--Category Axis--*/
  xaxis fitpolicy=splitrotate label='Rainy day? (0=No, 1 = Yes)';

  /*--Response Axis--*/
  yaxis label='# of Trips' grid;
run;

ods graphics / reset;
title;

/* Correlation of age, max temp, precipitation with # of trips */
ods noproctitle;
ods graphics / imagemap=on;

proc sort data=WORK.BIKE2 out=Work.SortTempTableSorted;
  where usertype ne ' ';
  by usertype;
run;

proc corr data=Work.SortTempTableSorted pearson nosimple noprob
  plots(maxpoints=none)=matrix;
  var no_of_trips;
  with age PRCP TMAX;
  by usertype;
run;

proc delete data=Work.SortTempTableSorted;
run;

/* Two-sample t-test for no of trips by rainy day */
ods noproctitle;
ods graphics / imagemap=on;

/*** Test for normality ***/
proc univariate data=WORK.BIKE2 normal mu0=0;
  ods select TestsForNormality;
  class rain;
  var no_of_trips;
run;

/*** t Test ***/
proc ttest data=WORK.BIKE2 sides=2 h0=0 plots(showh0);
  class rain;
  var no_of_trips;
run;