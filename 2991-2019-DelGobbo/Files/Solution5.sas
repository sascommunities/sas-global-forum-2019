*;
*  TO DO: Run the code once and then examine the log
*         for error messages.
*
*         Examine the data set names in the PROC DATASETS results.
*
*         Then recall the code, add the option to support
*         special characters in data set names (line 12),
*         and run the code.
*;

options validvarname=any validmemname=extend;

libname xl xlsx "&PATH\LabResults.xlsx" access=read;

proc datasets nolist;
  copy in=xl out=work;
run; quit;

ods html path="&PATH" file='Exercise5.htm' style=HTMLBlue;

title 'The WORK Library';

proc datasets library=work memtype=data; run; quit;

ods html close;

;*';*";*/;quit;run;
* Reference for code above: http://tinyurl.com/mjde9fc ;