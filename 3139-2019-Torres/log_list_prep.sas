/******************************************************************
* PROGRAM NAME :  log_list_prep.sas
* DESCRIPTION :   prepare and modify log and list
* AUTHOR:         zeke torres
* LinkedIn:       https://www.linkedin.com/in/zeketorres/
*******************************************************************/

/* obtain the path and number of sections of that path
******************************************************/
data _null_;
    cpy_sys_var1 ="%sysfunc(getoption(SYSIN))";
    call symput('cpy_sys_path'  ,cpy_sys_var1);
run;

/* pick up the sysparm value from the command line this enables the rest of the code to be OFF by default
* and only if a user enters the correct value below will the log/list file be copied to the project folder
************************************************************/
data _null_;
    prod="&sysparm";
    prod =lowcase(prod);
    prod =compress(prod);
    prod_key=0;
    /*** we want to create two types of namig conventions - prod and CR (code review)
    **** for prod or CR - we simply need the leading values in sysparm to match
    **************************************************************************/
    if prod in :('yes','live','prod','production','y','1') then do;
       prod_key=1;
    end;
    if prod in :('code','codereview','cr','2') then do;
       prod_key=2;
    end;
    call symput('cpy_sys_prod',prod_key);
run;


/*** we are going to prep and clean up the sas code path and sas code execution .sas ***/
data _null_;

      /** get the file name from the path ***/
      length temp_file_name  $700.;
      length temp_file_name2 $700.;
      length code_name       $250.;
      temp_file_name ="&cpy_sys_path";

      /** need to reverse to isolate the actual name ***/
      temp_file_name_r=reverse(temp_file_name);
      temp_file_name2 =scan(temp_file_name_r,1,'\');  /** you may need to adjust the back/forward slash to your os **/

      /** reversing back to final output name ***/
      temp_file_name2=reverse(temp_file_name2);
      temp_file_name2=left(temp_file_name2);
      temp_file_name2=compress(temp_file_name2);
      temp_file_name2=trimn(temp_file_name2);
      xlen=length(temp_file_name2);
      code_name=substr(temp_file_name2,1,250);
      code_name=scan(code_name,1,'.');

      zalen=(length(temp_file_name)) - xlen;

      fnl_path=substr(temp_file_name,1,zalen);
      fnl_path=compress(fnl_path);
      fnl_path=compbl(fnl_path);
      call symputx('cpy_fnl_path',fnl_path);
      call symputx('cpy_code_name_x',code_name);
run;


%macro dnull(job_class=);

/*** we will bring together the facts we need and append to revised log and list names ***/
    data _null_;
         /* get the system date and set format for it as yyyymmdd10
         *************************************/
         length tdate 8.;
         format tdate yymmdd10.;
         tdate="&sysdate9"d;
         length fdate $20.;
         fdate=tdate;
         fdate=put(tdate, yymmdd10.);
         fdate=tranwrd(fdate,"-","_");
         fdate=compress(fdate,"_");

         /* get the system time and compress
         ***************************/
         length stime $15.;
         stime="&systime";
         stime=compress(stime,":");

         * prepare the new log and list names using the new prefix code name now
         * add that to the final string of chars to get a useable set of file names
         ******************************************/
         length code_list $3500.;
         length code_log  $3500.;
         cpath="&cpy_fnl_path";
         cfile="&cpy_code_name_x";
         csval="&sysparm";
         code_list ="'" !!  cpath !! fdate !! "_" !! stime !! "_" !! csval  !! "_" !! cfile  !! ".lst" !!   "'";
         code_log  ="'" !!  cpath !! fdate !! "_" !! stime !! "_" !! csval  !! "_" !! cfile  !! ".log" !!   "'";
         code_list =compress(code_list);
         code_log  =compress(code_log);
         call symputx('cpy_sys_list',code_list);
         call symputx('cpy_sys_log' ,code_log);
    run;


    /* execute the new file names for both log and list */
    proc printto print = &cpy_sys_list  new;
    run;

    proc printto   log = &cpy_sys_log   new;
    run;
%mend;  *** end dnull macro;


%macro loopy();
    %if &cpy_sys_prod. =1 %then %do;
       %dnull(job_class= );
    %end;  /** end of the criteria if this is prod or not **/

    %if &cpy_sys_prod. =2 %then %do;
       %dnull(job_class=_CR);
    %end;  /** end of the criteria if this is prod or not **/
%mend;

%loopy();
