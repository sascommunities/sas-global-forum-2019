*;
*  TO DO: Run the code.
*
*         Optionally, add or remove SAS datasets in
*         the SELECT statement (Line 14).
*
*         Examine the SASHelp_Exercise8.xlsx file using Excel.
*;

libname xl xlsx "&PATH\SASHelp_Exercise8.xlsx";

proc datasets nolist;
  copy in=sashelp out=xl;
    select shoes class retail / memtype=data;
run; quit;

;*';*";*/;quit;run;
* Reference for code above: http://tinyurl.com/mjde9fc ;