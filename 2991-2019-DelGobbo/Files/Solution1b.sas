*;
*  TO DO: Line 9 - Add the option to support special 
*                  characters in SAS variable names,
*                  and then run the code.  Examine the 
*                  variable names in the PROC CONTENTS and
*                  PROC PRINT results.
*;

options validvarname=any;

proc import out=work.calcium
  file="&PATH\Calcium.csv"
  dbms=csv
  replace;
  guessingrows=max;
run; quit;

ods html path="&PATH" file='Exercise1b.htm' style=HTMLBlue;

title 'The WORK.CALCIUM Data Set';

proc contents data=work.calcium varnum; run; quit;

proc print data=work.calcium(obs=10);
  var sex 
      'unique subject identifier'n 
      'baseline result in std. units'n
      'baseline collection date/time'n;
run; quit;

ods html close;

;*';*";*/;quit;run;
* Reference for code above: http://tinyurl.com/mjde9fc ;