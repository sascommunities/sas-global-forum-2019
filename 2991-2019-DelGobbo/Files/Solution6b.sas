*;
*  TO DO: Line 18 - Specify the Excel m/d/yyyy h:mm 
*                   number format for the datetime variables.
*
*         Examine the LabResults_Exercise6b.xlsx file using Excel.
*;

ods _all_ close;

ods Excel file="&PATH\LabResults_Exercise6b.xlsx"
  options(sheet_name='#byval(lbtest)' suppress_bylines='yes');

proc print data=sample.LabResults noobs label;
  by lbtest;
  var usubjid lbtest age ageu sex baseline_lbstresn baseline_lbstresu
      visit5_lbstresn visit5_lbstresu;
  var baseline_lbdtn 
      visit5_lbdtn   / style(column)=[tagattr='format:m/d/yyyy h:mm'];
  format baseline_lbdtn visit5_lbdtn datetime18.;
run; quit;

ods Excel close;

* ;*';*";*/;quit;run;
* Reference for code above: http://tinyurl.com/mjde9fc ;