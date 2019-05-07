*;
*  TO DO: Run the code and then examine the variable names
*         in the PROC CONTENTS and PROC PRINT results.
*;

proc import out=work.calcium
  file="&PATH\Calcium.csv"
  dbms=csv
  replace;
  guessingrows=max;
run; quit;

ods html path="&PATH" file='Exercise1a.htm' style=HTMLBlue;

title 'The WORK.CALCIUM Data Set';

proc contents data=work.calcium varnum; run; quit;

proc print data=work.calcium(obs=10);
  var sex
      unique_subject_identifier
      baseline_result_in_std__units
      baseline_collection_date_time;
run; quit; 

ods html close;

;*';*";*/;quit;run;
* Reference for code above: http://tinyurl.com/mjde9fc ;