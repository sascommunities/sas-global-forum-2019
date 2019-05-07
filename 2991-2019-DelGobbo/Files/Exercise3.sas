*;
*  TO DO: Line 15 - Specify the DBMS engine value to 
*                   import XLSX files.
*
*         Line 17 - Supply the statement to import the 
*                   CALCIUM worksheet.
*
*         Examine the PROC CONTENTS and PROC PRINT results.
*;

options validvarname=any;

proc import out=work.calcium 
  file="&PATH\LabResults.xlsx"
  dbms=
  replace;
  ;
  format 'visit 5 collection date/time'n
         'baseline collection date/time'n e8601dt19.;
run; quit;

ods html path="&PATH" file='Exercise3.htm' style=HTMLBlue;

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