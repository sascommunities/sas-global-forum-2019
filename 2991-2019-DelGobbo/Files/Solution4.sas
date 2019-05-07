*;
*  TO DO: Line 13 - Specify the SET statement needed to set
*                   the CALCIUM worksheet from the XL library.
*
*         Examine the PROC CONTENTS and PROC PRINT results.
*;

options validvarname=any;

libname xl xlsx "&PATH\LabResults.xlsx" access=read;

data work.calcium;
set xl.calcium;
attrib 'Baseline Collection Date/Time'n 
       'Visit 5 Collection Date/Time'n  format=e8601dt19.;
run;

ods html path="&PATH" file='Exercise4.htm' style=HTMLBlue;

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