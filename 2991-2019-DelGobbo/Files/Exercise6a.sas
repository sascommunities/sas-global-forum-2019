*;
*  TO DO: Run the code and then examine the 
*         LabResults_Exercise6a.xlsx file using Excel.
*;

ods _all_ close;

ods Excel file="&PATH\LabResults_Exercise6a.xlsx"
  options(sheet_name='#byval(lbtest)' suppress_bylines='yes');

proc print data=sample.LabResults noobs label;
  by lbtest;
  var usubjid lbtest age ageu sex baseline_lbstresn baseline_lbstresu
      visit5_lbstresn visit5_lbstresu baseline_lbdtn visit5_lbdtn;
  format baseline_lbdtn visit5_lbdtn datetime18.;
run; quit;

ods Excel close;

;*';*";*/;quit;run;
* Reference for code above: http://tinyurl.com/mjde9fc ;