/* Please specify the folder path of the Bikeshare CSV file */
%let BikeData = %str(/nfs/rdcx200/ifs/edm_data/Testdata/Bikes);

/* Please specify the folder path of the FCI macro files */
%let SGFCode = %str(/r/ge.unx.sas.com/vol/vol610/u61/minlam/projects/SGF2019/Code);

/* A CAS session is required */
cas _thisCAS;
caslib _ALL_ assign;

/* Call the IMPORT procedure to read the CSV file because the datetime column in the CSV file 
   can only be read using the anydtdtm40. format */
proc import datafile = "&BikeData./BikeSharingDemand_Train.csv" dbms = csv replace
            out = CASUSER.BikeSharingDemand_Master;
run;

/* Prepare the training data */
data CASUSER.BikeSharingDemand_Master;
   set CASUSER.BikeSharingDemand_Master;

   /* Round the windspeed to the nearest integer */
   windspeed = round(windspeed);

   /* Determine if the date falls on a weekend */
   if (workingday eq 0 and holiday eq 0) then weekend = 1;
   else weekend = 0;

   /* Extract individual chronological elements */
   rental_date = datepart(datetime);
   rental_weekday = weekday(rental_date);
   rental_hour = hour(datetime);

   /* Divide the data into a training period (0) and four monitoring periods (1,2,3,4) */
        if ('01JAN2011'd <= rental_date <= '31DEC2011'd) then _PERIOD_ = 0;
   else if ('01JAN2012'd <= rental_date <= '31MAR2012'd) then _PERIOD_ = 1;
   else if ('01APR2012'd <= rental_date <= '30JUN2012'd) then _PERIOD_ = 2;
   else if ('01JUL2012'd <= rental_date <= '30SEP2012'd) then _PERIOD_ = 3;
   else _PERIOD_ = 4;

   /* Put rental hour into custom groups that are appropriate for the business operation */
   length rental_hour_group $ 12;
   if (rental_hour in (2:5)) then rental_hour_group = '2AM - 5AM';
   else if (rental_hour in (6:8)) then rental_hour_group = '6AM - 8AM';
   else if (rental_hour in (9:11)) then rental_hour_group = '9AM - 11AM';
   else if (rental_hour in (12:16)) then rental_hour_group = '12NOON - 4PM';
   else if (rental_hour in (17:19)) then rental_hour_group = '5PM - 7PM';
   else rental_hour_group = '8PM - 1AM';

   label holiday = 'Is the Day Considered a Holiday?';
   label humidity = 'Relative Humidity in Percent';
   label rental_weekday = 'Day of the Week of the Rental';
   label rental_hour_group = 'Hour Group of the Day of the Rental';
   label temp = 'Temperature in Celsius';
   label weather = 'Weather Condition';
   label windspeed = 'Wind Speed';
run;

/* Review the data contents */
proc cas;   
   action table.columnInfo / table = {caslib = "CASUSER" name = "BikeSharingDemand_Master"};
   run;
   
   action aggregation.aggregate /
      table = {caslib = "CASUSER" name = "BikeSharingDemand_Master" groupBy = {{name = "_PERIOD_"}}
      computedVars = {{name = 'ConstantOne'}} 
      computedVarsProgram = 'ConstantOne = 1;'}
      saveGroupByRaw = True saveGroupByFormat = False
      varSpecs={{name='ConstantOne' agg = 'N' columnNames={'N'}}
                {name='rental_date' agg='MIN' format = "datetime18." columnNames={'Mininum rental_date'}}
                {name='rental_date' agg='MAX' format = "datetime18." columnNames={'Maximum rental_date'}}}
      casOut = {caslib = "CASUSER" name = "_AggrOut_", replace=true, replication=0};
   run;
      
   action table.fetch / table = {caslib = "CASUSER" name='_AggrOut_'};
   run;
quit;

/* Divide the master dataset into a Training partition and four monitoring partitions */
data CASUSER.BikeShare_0_2011_01to12
     CASUSER.BikeShare_1_2012_Q1
     CASUSER.BikeShare_2_2012_Q2
     CASUSER.BikeShare_3_2012_Q3
     CASUSER.BikeShare_4_2012_Q4;

   set CASUSER.BikeSharingDemand_Master;

   select (_PERIOD_);
      when (0) output CASUSER.BikeShare_0_2011_01to12;
      when (1) output CASUSER.BikeShare_1_2012_Q1;
      when (2) output CASUSER.BikeShare_2_2012_Q2;
      when (3) output CASUSER.BikeShare_3_2012_Q3;
      when (4) output CASUSER.BikeShare_4_2012_Q4;
      otherwise;
   end;

   keep count;
   keep holiday rental_hour_group rental_weekday season weather weekend workingday;
   keep atemp temp humidity windspeed;
run;

/* Build the Poisson regression model */
filename _MDLSCR_ TEMP;
proc cas;
   action regression.genmod result = genmodResult status = scode /
      table = {caslib = "CASUSER" name = "BikeShare_0_2011_01to12"}
      class = {{vars = {"holiday" "rental_weekday" "rental_hour_group" "weather"}
               order = "FREQ" descending = TRUE
               param = "GLM" countMissing = False}}
      model = {depVars = {{name = "count" options = {levelType = "INTERVAL"}}}
               dist = "POISSON" link = "LOG" ss3 = TRUE
               effects = {{vars = {"holiday" "rental_weekday" "rental_hour_group" "weather "
                                   "temp" "humidity" "windspeed"}
                         }}
               }
      optimization = {technique = "NEWRAP" fConv = 0 gConv = 1e-10 absFConv = 1e-10 absGConv = 1e-8 maxiter = 1000
                      itHist = "SUMMARY"}
      code = {pCatAll = True comment = False tabForm = True indentSize = 0 lineSize = 254}
      ;            
   run;

   if (scode.severity == 0) then do;
      print genmodResult;
      saveresult genmodResult['_code_'] file = _MDLSCR_;
   end;
quit;

/* Score the reference and the monitoring datasets */

data CASUSER.BikeShare_0_2011_01to12_score;
   set CASUSER.BikeShare_0_2011_01to12;
   %include _MDLSCR_;
run;

/* Predicted Counts Versus the Observed Counts of the Poisson Regression Model */
proc sgplot data = CASUSER.BikeShare_0_2011_01to12_score;
   scatter x = count y = P_count;
   xaxis grid;
   yaxis grid;
run;

data CASUSER.BikeShare_1_2012_Q1_score;
   set CASUSER.BikeShare_1_2012_Q1;
   %include _MDLSCR_;
run;

data CASUSER.BikeShare_2_2012_Q2_score;
   set CASUSER.BikeShare_2_2012_Q2;
   %include _MDLSCR_;
run;

data CASUSER.BikeShare_3_2012_Q3_score;
   set CASUSER.BikeShare_3_2012_Q3;
   %include _MDLSCR_;
run;

data CASUSER.BikeShare_4_2012_Q4_score;
   set CASUSER.BikeShare_4_2012_Q4;
   %include _MDLSCR_;
run;

/* Prepare the target and the predictor specification data */

data CASUSER.TargetSpec;
   length NAME $ 32;
   length PRIOR 8;

   NAME = 'P_count';
   PRIOR = 1;
run;

data CASUSER.PredictorSpec;
   length NAME $ 32;
   length LEVEL $ 8;
   length QMISSNOM $ 1;
   length NLEVEL 8;

   input NAME $ 1-20 LEVEL $ 21-28 QMISSNOM $ 31 NLEVEL 33;
   datalines;
holiday             NOMINAL   N 2
rental_hour_group   NOMINAL   N 6
rental_weekday      NOMINAL   N 7
season              NOMINAL   N 4
weather             NOMINAL   N 3
weekend             NOMINAL   N 2
workingday          NOMINAL   N 2
atemp               INTERVAL
humidity            INTERVAL
temp                INTERVAL
windspeed           INTERVAL
run;

/* The BikeShare_0_2011_01to12_score is the reference baseline,
   and the other datasets will compare with it */

data CASUSER.MonitorDataSpec;
   length DataName $ 32;
   length DisplayName $ 32;

   DataName = 'BikeShare_0_2011_01to12_score';
   DisplayName = '2011';
   output;

   DataName = 'BikeShare_1_2012_Q1_score';
   DisplayName = '2012 Q1';
   output;

   DataName = 'BikeShare_2_2012_Q2_score';
   DisplayName = '2012 Q2';
   output;

   DataName = 'BikeShare_3_2012_Q3_score';
   DisplayName = '2012 Q3';
   output;

   DataName = 'BikeShare_4_2012_Q4_score';
   DisplayName = '2012 Q4';
   output;
run;

%include "&SGFCode./compute_fci_intpred.sas";
%include "&SGFCode./compute_fci_nompred.sas";
%include "&SGFCode./create_fci_report.sas";
%include "&SGFCode./create_macro_from_column.sas";

ods graphics / reset width = 8in height = 6in;

%create_fci_report
(
   InCASLib = CASUSER,                  /* CAS library of the input specification datasets */
   OutCASLib = CASUSER,                 /* CAS library of the output datasets */
   MDataCASLib = CASUSER,               /* CAS library of the monitoring datasets */
   MonitorDataSpec = MonitorDataSpec,   /* Monitoring data specification dataset */
   TargetSpec = TargetSpec,             /* Target specification dataset */
   PredictorSpec = PredictorSpec,       /* Predictor specification dataset */
   OutFCIData = OutFCIData,             /* Output Feature Contribution Index data */
   Debug = N                            /* Display debugging information (Y/N)? */
);

/* Print all rows in the output FCI data */
proc cas;
   action table.fetch /
      table = {caslib = "CASUSER" name = "OutFCIData"}
      from = 1 to = 2147483647 maxRows = 2147483647;
   run;
quit;

/* Display the Association Structure Between the rental_hour_group
   and the humidity Predictors by Quarter */
proc format;
   value period_fmt 0 = '2011' 1 = '2012 Q1' 2 = '2012 Q2' 3 = '2012 Q3' 4 = '2012 Q4';
run;

proc sgplot data = CASUSER.BikeSharingDemand_Master;
   vbox humidity / category = rental_hour_group group = _PERIOD_ groupdisplay = cluster;
   xaxis values = ('2AM - 5AM' '6AM - 8AM' '9AM - 11AM' '12NOON - 4PM' '5PM - 7PM' '8PM - 1AM');
   yaxis grid;
   format _PERIOD_ period_fmt.;
run;