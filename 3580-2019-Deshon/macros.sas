/******************************************************************************/
/* Create a macro that rounds a value to the nearest penny (0.01).            */
/******************************************************************************/

%macro round2penny(whatvar);
  if &whatvar ne . then &whatvar = round(&whatvar,0.01);
%mend;
 
/******************************************************************************/
/* expo_round.sas --                                                          */
/* This macro performs a form of expoential rounding.                         */
/* It rounds numbers to increasingly larger values as their value increases.  */
/* It can be used for reporting sales when an exact number is not needed or   */
/* when giving an exact number might be more confusing.                       */
/* This is a FUNCTION-type macro.                                             */
/* USAGE:                                                                     */
/*  approx_sales = %expo_rounded(sales);                                      */
/******************************************************************************/

%macro expo_round(what_var);

  ifn(&what_var lt     1000,round(&what_var,     100),        /** LT      1,000, round to        100 **/
  ifn(&what_var lt    10000,round(&what_var,    1000),        /** LT     10,000, round to      1,000 **/
  ifn(&what_var lt   100000,round(&what_var,   10000),        /** LT    100,000, round to     10,000 **/
  ifn(&what_var lt  1000000,round(&what_var,  100000),        /** LT  1,000,000, round to    100,000 **/
  ifn(&what_var lt 10000000,round(&what_var, 1000000),        /** LT 10,000,000, round to  1,000,000 **/
                            round(&what_var,10000000),.)))))  /** GE 10,000,000, round to 10,000,000 **/

%mend;
 
/******************************************************************************/
/* Create a macro that flips missings to zero.                                */
/* This macro actually CHANGES the value of the variable.                     */
/* If you don't want to change the value, but merely USE a zero instead of a  */
/* missing value, use the macro zeronotmiss instead.                          */
/******************************************************************************/

%macro miss2zero(whatvar);
  if &whatvar = . then &whatvar = 0;
%mend;
 
/******************************************************************************/
/* Create a macro that flips zeroes to missing.                               */
/* This macro actually CHANGES the value of the variable.                     */
/* If you don't want to change the value, but merely USE a missing value      */
/* instead of a zero, use the macro missnotzero instead.                      */
/******************************************************************************/

%macro zero2miss(whatvar);
  if &whatvar = 0 then &whatvar = .;
%mend;
 
/*******************************************************************************/
/* Create a macro that uses a missing value if the value passed to it is zero. */
/* This macro actually DOESN'T CHANGE the value of the variable, it only       */
/* uses a missing value if it was given a zero.                                */
/* If you want to CHANGE the value, use the macro zero2miss instead.           */
/*******************************************************************************/

%macro missnotzero(whatvar);
  choosen((&whatvar=0)+1,&whatvar,.)
%mend;
 
/*******************************************************************************/
/* Create a macro that uses zero if the value passed to it is missing.         */
/* This macro actually DOESN'T CHANGE the value of the variable, it only       */
/* uses a zero if it was given a missing value.                                */
/* If you want to CHANGE the value, use the macro miss2zero instead.           */
/*******************************************************************************/

%macro zeronotmiss(whatvar);
  choosen((&whatvar=.)+1,&whatvar,0)
%mend;
 

/*****************************************************************************/
/* file_date.sas --                                                          */
/* This is a "function" macro to easily determine the update date of any     */
/* file.  It can be used to test the age of an imported spreadsheet to make  */
/* sure it is a reasonably-recent version.                                   */
/* USAGE: my_file_date = %file_date("fully_qualified_path_and_name");        */
/* The path and file may or may not be quoted.                               */
/*****************************************************************************/

%macro file_date(file_path_and_name);
  ((filename("_fd&sysjobid","%bquote(&file_path_and_name)")*0) +
  input(finfo(fopen ("_fd&sysjobid"), "Last modified"),anydtdte18.))
%mend;
 
/******************************************************************************/
/* rand_between.sas --                                                        */
/* This macro returns a random integer between two numbers.                   */
/* USAGE:                                                                     */
/*    e.g. to return a random string 'A', 'B', 'C', or 'D':                   */
/*      mystring = substr('ABCD',%rand_between(1,4),1);                       */
/* NOTES:                                                                     */
/* The macro acts like a regurlar SAS function and can be used in any         */
/* expression that needs a numeric value.                                     */
/* It expects two numbers as parameters.                                      */
/* If either of the two numbers are missing, the macro will return a missing  */
/* value.                                                                     */
/* The numbers can be negative, positive, or zero.                            */
/* If the numbers are not whole, only the integer portion is considered.      */
/* It doesn't matter if the high number is first or last; the result will be  */
/* the same.                                                                  */
/* If the two numbers are equal, the integer portion of that number will      */
/* always be returned.                                                        */
/* If a string is passed to this macro, the results will be unpredictable.    */
/******************************************************************************/

%macro rand_between(number1,number2);
  choosen((&number1=. or &number2=.)+1,
    int(ranuni(0)*(max(int(&number1),int(&number2))-min(int(&number1),int(&number2))+1))+min(int(&number1),int(&number2))
    ,.)
%mend;
 
/******************************************************************************/
/* get_sas_progname.sas --                                                    */
/* This program gets the name and path of the program currently being         */
/* executed from the Windows environment variables.  It needs to be run at    */
/* the very top of the program.  The Windows environment variables may be     */
/* changed every time a SAS program is initiated in different sessions.  This */
/* program "freezes" the values in SAS macro variables so they will be the    */
/* same for any given session throughout the run of the program.              */
/******************************************************************************/

%macro get_sas_progname;
  %global sas_execfilepath sas_execfilename;
  %let sas_execfilepath = %sysget(SAS_EXECFILEPATH);
  %let sas_execfilename = %sysget(SAS_EXECFILENAME);
  %put NOTE: Macro variable %str(&)sas_execfilepath = &sas_execfilepath..;
  %put NOTE: Macro variable %str(&)sas_execfilename = &sas_execfilename..;
%mend;


 
/**************************************************************************/
/* swap.sas --                                                            */
/* Use call ALLPERM to swap two values without having to create a         */
/*  temp variable.                                                        */
/* ALLPERM checks to make sure the variables are the same type and same   */
/* length.                                                                */
/* Even though ALLPERM checks for different types and lengths, the error  */
/* message isn't very helpful, because it refers to ALLPERM, but doesn't  */
/* give  line number.  Also, the programmer may not be aware that the     */
/* SWAP macro even calls ALLPERM.  So this macro delivers a slightly more */
/* meaningful message, giving the names of the variables and the fact     */
/* that it is the SWAP macro causing the error.  It then passes control   */
/* to CALL ALLPERM, which will abort the data step.                       */
/* Notice that the above condition is a RUNTIME error, not a COMPILE      */
/* error.                                                                 */
/** 
https://communities.sas.com/t5/SASware-Ballot-Ideas/Create-a-new-function-SWAP/idi-p/327598
**/
/**************************************************************************/

%macro swap(var1,var2);
  /** When there are only two permutations,                  **/
  /** The SECOND permutation is the reverse of the ORIGINAL! **/
  if vtype(&var1) ne vtype(&var2) then do;
    putlog "ERROR: SWAP macro called for variables &var1 and &var2, but they are different types!";
    end;
  if vlength(&var1) ne vlength(&var2) then do;
    putlog "ERROR: SWAP macro called for variables &var1 and &var2, but they are different lengths!";
    end;
  call allperm(2,&var1,&var2);
%mend; 
%macro make_var(var,len,logoption);
* This routine creates a unique macro variable name that can be used in any routine;
* without fear of coliding with other variables of the same name.;
* It can be used for temporary file names, temporary data step variables,;
* temporary file references, temporary "goto" labels in a macro, or temporary formats.;
%global &var;
%let &var = _%substr(%sysfunc(compress(%sysfunc(uuidgen()),'-')),1,31);
%if "&len" ne "" %then %do;
  %let &var = %substr(&&&var,1,&len);
  %end;
%if %upcase("&logoption") ne "NOLOG" %then %do;
  %put NOTE: New macro variable &var created as &&&var;
  %end;
%mend;
 
%macro progress;
  %make_var(progcntr);
  %make_var(recocntr);
  %make_var(datstrng);
  drop
    &progcntr
    &recocntr
    &datstrng
    ;
  length &datstrng $ 21;
  &progcntr + 1;
  &recocntr + 1;
  if &progcntr = 100000 then do;
    &datstrng = put(datetime(),datetime21.);
    file log;
    put &datstrng ' RecordCounter=' &recocntr comma13.;
    &progcntr = 0;
    end;
%mend;

