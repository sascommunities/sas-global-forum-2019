*;
*  TO DO: Review the PROC SQL code that creates the
*         LABRESULTS_SUBSET view.
*
*         Line 21 - Specify the LBTEST value to subset
*                   the data to include only CALCIUM results.
*
*         Line 26 - Specify the worsheet name (CALCIUM).
*
*         Examine the LabResults_Exercise7.xlsx file using Excel.
*;

proc sql;
  create view work.LabResults_Subset as
  select usubjid, lbtest, age, ageu, sex, baseline_lbstresn,
         baseline_lbstresu, visit5_lbstresn, visit5_lbstresu,
         baseline_lbdtn, visit5_lbdtn
  from sample.LabResults;
quit;

proc export data=work.LabResults_Subset(where=(lbtest eq ''))
  file="&PATH\LabResults_Exercise7.xlsx"
  dbms=xlsx
  replace
  label;
  sheet='';
run; quit;

;*';*";*/;quit;run;
* Reference for code above: http://tinyurl.com/mjde9fc ;