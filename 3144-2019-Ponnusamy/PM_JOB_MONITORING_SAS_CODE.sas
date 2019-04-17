
%macro read_hist();

 filename mylist pipe "ls -ltr /opt/sas/platform/pm/work/history"; 
  /*please replace /opt/sas/platform/ with the IBM Spectrum LSF Process Manager Installation directory at your site*/
  /*pipe enables you to invoke a program outside of SAS and redirect the programs output to SAS */

/*get todays date*/
data _null_;
 call symput ('run_dt',day(today()));
run;
%put &run_dt.;

/*get the file listing of JS_TOP/work/history directory in to a SAS dataset*/
data myfiles;
 infile mylist lrecl=400 truncover;
 length permis $10 filelink $1 owner $20 group $20 size $8 month $3 day $2 time $20 filename $200;
 input permis $ filelink $ owner $ group $ size $ month $ day $ time $ filename $;
run;

/*get the filenames for today */
data myfiles (keep=filename);
 set myfiles nobs=obs;
 if day=&run_dt. then output;
run;

data _null_;
 set myfiles end=last;
 call symput('hist_file_nm' || trim(left(put(_n_,8.))),filename);
            /*as you read each filename assign it to variable*/
 if last then call symput('total',trim(left(put(_n_,8.)))); 
             /*get the total count of history.log files that you need to read for the day*/
run;
%put &total;

/*---copy the content of all the history files to one single file---*/

%let hist_path=/opt/sas/platform/pm/work/history/; /*replace this with the PM install directory at your site*/
%global op_path;
%let op_path=/tmp/; /*your output location*/

%do i=1 %to &total;
    %if &i=1 %then
        %do;
           data _null_;
	      call system("rm &&op_path.hist_append.txt");
             /*create a new file, every time the program runs*/
	      call system("cp &hist_path.&&hist_file_nm&i &op_path.hist_append.txt"); 
             /*copy the content to that new file*/
           run;
        %end;
    %else
        %do;
           data _null_;
	      call system("cat &hist_path.&&hist_file_nm&i >> &op_path.hist_append.txt");
             /*append the content of further history.log files */
           run;
        %end;
%end;

%mend read_hist;
%read_hist;


filename fnam "&op_path./hist_append.txt";
data finished_jobs(drop= rec firstvar varlen);
  infile fnam length=linelen lrecl=5000;       
  length user_id $20. flow_run_id $10. job_flow $40. job_name $100.  status $15. job_id $20. job_state $10. job_status_cd 8. start_time 8. time_stamp 8. finish_time 8. cpu_usage_sec 8.;
  format start_time datetime18. time_stamp datetime18. finish_time datetime18.;

  input firstvar $ 1-1 @; 
  varlen=linelen-1; 
  input @2 rec $varying1500. varlen; 
  /* convert UNIX epoch time to SAS time */
  time_stamp=input(scan(rec,5,'"'),20.)+315619200; 
  status=translate(scan(rec,9,'"'),'','"'); 
  if status='Finished job' and (datepart(time_stamp)=today()) then
   do;
     user_id=translate(scan(rec,2," "),'','"');
     flow_run_id=translate(scan(scan(rec,4," "),1,':'),'','"');
     job_flow=translate(scan(scan(rec,4," "),3,':'),'','"');
     job_name=translate(scan(scan(rec,4," "),4,':'),'','"');
     job_state=scan(scan(scan(rec,11,'"'),2,'|'),2,'=');
     job_id=scan(scan(scan(rec,11,'"'),1,'|'),2,'=');
     job_status_cd=input(scan(scan(scan(rec,11,'"'),3,'|'),2,'='),4.); 
     start_time=input(scan(scan(scan(rec,11,'"'),4,'|'),2,'='),20.)
+315619200;    /* convert UNIX epoch time to SAS time*/
     finish_time=input(scan(scan(scan(rec,11,'"'),5,'|'),2,'='),20.)
+315619200;
     cpu_usage_sec=input(scan(scan(scan(rec,11,'"'),5,'|'),2,'='),20.)
+315619200;
     output;
   end;
run;

filename fnam "&op_path./hist_append.txt";
data scheduled_jobs(drop= rec firstvar varlen status);
  infile fnam length=linelen lrecl=5000;
  length user_id $20. flow_run_id $10. job_flow $40. job_name $100. job_id $20. exec_start_time 8. exec_host $30.;
  format exec_start_time datetime18.;

  input firstvar $ 1-1 @;
  varlen=linelen-1;
  input @2 rec $varying1500. varlen;
  exec_start_time=input(scan(rec,5,'"'),20.)+315619200;
  status=translate(scan(rec,9,'"'),'','"');
  if status='Execute job' and (datepart(exec_start_time)=today()) then
   do;
     user_id=translate(scan(rec,2," "),'','"');
     flow_run_id=translate(scan(scan(rec,4," "),1,':'),'','"');
     job_flow=translate(scan(scan(rec,4," "),3,':'),'','"');
     job_name=translate(scan(scan(rec,4," "),4,':'),'','"');
     job_id=scan(scan(scan(rec,11,'"'),1,'|'),2,'=');
     exec_host=scan(scan(scan(rec,11,'"'),2,'|'),2,'=');
     output;
   end;
run;

proc sql noprint;
  create table job_details
   as
    select 
       datepart(exec_start_time) as run_date format=date8.,
       a.*,
       b.finish_time,
       b.job_state,
       b.job_status_cd,
       (b.finish_time - a.exec_start_time)/60 as run_time
    from scheduled_jobs a 
       left outer join 
         finished_jobs b
       on a.flow_run_id=b.flow_run_id and a.job_id=b.job_id
    order by exec_start_time;
run;

proc sql noprint;
create table failed_jobs
 as
   select   
          user_id, 
          flow_run_id, 
          job_flow, 
          job_name, 
          status, 
          job_id, 
          job_state, 
          job_status_cd, 
          start_time, 
          finish_time, 
          cpu_usage_sec
    from finished_jobs 
    where job_status_cd >= 2 and timepart(finish_time)> time()- 1800;
run;

proc sql noprint;
create table long_run_jobs 
  as
    select
           user_id, 
           flow_run_id, 
           job_flow, 
           job_name, 
           job_id, 
           exec_start_time, 
           (time()-timepart(exec_start_time))/60 as run_time_min
     from job_details 
     where finish_time is null and timepart(exec_start_time)< time()- 7200;
run;
