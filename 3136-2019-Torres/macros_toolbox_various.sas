/******************************************************************
* PROGRAM NAME :  macros_toolbox_various.sas
* DESCRIPTION :   basic stats and contents on sas data
* AUTHOR:         zeke torres
* LinkedIn:       https://www.linkedin.com/in/zeketorres/
*******************************************************************
* macro naming conventions to be aware of
*       main libname for temp data is:   work.
*          - you can adjust this by updating to suite your needs
*       temp dataset prefix is: tmpx_ and tmpz_
*          - these two are stored within work. lib and
*            if they are created they are deleted using
*            proc datasets delete and that prefix
*       *** special notice ***
*       it is important for you to decide if the prefix mentioned
*       above and overall naming convention will cause any mix up
*       with existing or future code
*
*       inds - is meant to indicate the "incoming dataset"
*       vartochk - is meant to hold variable name and/or names
*            the vars should be listed one by one and space delimited
*            Here is an example:
*            vartochk= var_one  var_two  var_three
*
*******************************************************************
* macro mkworktsrc()
*     this macro creates subset data for the parent macro that calls it
*     this way the original ds/table isnt going to be tampered or locked
*     caution on using this method and tool box to explore large data
*     without obs limits first to determine which next method to use
*     this macro is used within these next macros:
*        dsreport1
*        field_stats
*        field_top15
*        field_freq
*        field_freqdt
*        field_numbers
*
*******************************************************************
* macro dsreport1(inds=)
*       performs proc contents on the data and prints sample 10
*       rows (first 10) the contents information is condensed
*******************************************************************
* macro field_stats(inds=,vartochk=)
*       this will check fields like -id- to see if they are unique
*       or not this is an ideal macro for fields like
*          patient id, index type ids, claim number
*******************************************************************
* macro field_top15(inds=,vartochk=)
*       this will check fields and provide a freq which then is
*       sorted by descending occrnce only the top 15 are printed
*******************************************************************
* macro field_freq(inds=,vartochk=)
*       performs a proc frequency on field specified. Caution
*       against using cms fields like provider/hospital, phone
*******************************************************************
* macro field_freqdt(inds=,vartochk=)
*       performs a proc frequency on field specified. Caution
*       against using cms fields like but for a date field
*       the date will be formated in yyyymm.
*******************************************************************
* macro field_numbers(inds=,vartochk=)
*       this will check amount fields to see get
*       basic info on them like
*       min max mean p10 p50 etc
*       with just a few rows of output
******************************************************************/


%macro mkworktsrc();
         /* keep data for use in freq and counts */
         data work.tmpz_&sysjobid ;
             set &inds (keep=&vartochk);
              length validation $35.;
              /* use this field -validation - to allow easier presentation */
              validation='number_of:';
         run;
%mend;


%macro delworksrc();
      /*** this will clean up tables created - pay special attention to the prefix ***/
      /*** if you happen to use this kind of prefix in your existing code you will ***/
      /*** need to modify this macro code to a prefix style that wont cause issues ***/

      proc datasets lib= work noprint;
           delete tmpy_: ;
           delete tmpz_: ;
      run;

%mend;


%macro dsreport1(inds=);
         data _null_;
             src_scan=scan("&inds",2,'.');
             call symput('src',src_scan);
         run;

         ods proclabel="Contents of file: &src";
         /* only keep certain fields from contents */
         proc contents data=&inds     noprint
                       out=work.tmpz_table_details
                       (keep=memname
                             varnum
                             nobs
                             crdate
                             idxusage
                             sorted
                             name
                             type
                             length
                             rename=(memname=data_set_name)
                             );
         run;

         data work.tmpz_table_facts
                        (keep=data_set_name
                              varnum
                              nobs
                              idxusage
                              sorted
                              crdate
                              rename=(varnum  =data_set_max_vars
                                      nobs    =data_set_num_obs
                                      idxusage=data_set_index_usage
                                      sorted  =data_set_sorted_flag
                                      crdate  =data_set_create_date
                                      ))
              work.tmpz_table_details
                        (keep=data_set_name
                              field_type
                              length
                              name
                              varnum
                              rename=(name  =field_name
                                      length=field_byte_length
                                      varnum=field_seq
                                      ));
              set work.tmpz_table_details;

             if type='1' then length=.;
             if type='1' then field_type='Num';
             if type='2' then field_type='Chr';
             drop type;
              name=upcase(name);
         run;

         /* get totals from content details on data */
         proc sort data=work.tmpz_table_facts;
         by data_set_name descending data_set_max_vars;
         run;

         /* rename fields to something client can understand */
         proc sort data=work.tmpz_table_facts nodupkey;
         by data_set_name ;
         run;

         /* print totals for the table */
         ods proclabel="Details of rows in file: &src";
         proc print data=work.tmpz_table_facts;
         title "data table facts: &src";
         run;
         title;

         proc sort data=work.tmpz_table_details ;
         by data_set_name field_type field_byte_length field_name;
         run;

         ods proclabel="Details of columns file: &src";
         proc print data=work.tmpz_table_details width=uniform;
         title "data table facts: &src";
         run;
         title;

         /* print 30 rows of data for sample */
         ods proclabel="Sample of Rows: &src";
         proc print data=&inds (obs=10) width=uniform;
         title "Sample Output - &src set to 10 rows if they exist";
         run;
         title;

%mend;  ****************** end macro;





/* this will check fields like -id- to see if they are unique or not */
%macro field_stats(inds=,vartochk=);
      data _null_;
           src_scan=scan("&inds",2,'.');
           call symput('src',src_scan);
      run;

          %mkworktsrc;

      %let dschk_cnt = %sysfunc(countw(&vartochk, ' '));
      %do ggg = 1 %to &dschk_cnt;
          %let local_var = %scan(&vartochk, &ggg);


          proc freq data=work.tmpz_&sysjobid  noprint;
          title1 "audit of data - &inds - for field &local_var";
          by validation;
              table &local_var /nocol norow nopercent out=work.tmpy_&sysjobid (drop=percent);
          run;
          title;

          proc summary data=work.tmpy_&sysjobid  nway noprint;
              class validation;
              var count;
              output out=work.tmpy_&sysjobid  (drop=_type_ _freq_)
                           n=count_of_distinct_values
                           max(count)=validate_unique;
          run;

          data work.tmpy_&sysjobid;
              set work.tmpy_&sysjobid;
              length validation $35.;
              validation="&local_var";
                is_field_unique='yes';
                if validate_unique gt 1 then do;
                   is_field_unique='no';
                end;
                drop validate_unique;
          run;

              ods proclabel="Validation of &local_var in: &src";
          proc print data=work.tmpy_&sysjobid  width=uniform;
              title1 "validating: &local_var  variable  in: &src - &inds";
              title2 "is field unique check";

          run;
          title;

      %end; *** end of do loop;
          %delworksrc();

%mend;  ******************** end macro;




%macro field_top15(inds=,vartochk=);
     data _null_;
          src_scan=scan("&inds",2,'.');
          call symput('src',src_scan);
     run;

         %mkworktsrc;

     %let dschk_cnt = %sysfunc(countw(&vartochk, ' '));
     %do ggg = 1 %to &dschk_cnt;
         %let local_var = %scan(&vartochk, &ggg);


         proc freq data=work.tmpz_&sysjobid   order=freq noprint;
         title1 "audit of data - &inds - for field &local_var";

             table &local_var  /nocol norow  out=work.tmpy_&sysjobid  ;
         run;
         title;


         data work.tmpy_&sysjobid ;
             set work.tmpy_&sysjobid  (obs=15);
             if percent lt 0 then do;
                 &local_var = 'missing';
             end;
         run;

         ods proclabel="Top 15 of &local_var variable in: &src";
         proc print data=work.tmpy_&sysjobid  noobs width=uniform;
         where percent gt 0;
         title "Top 15 of: &local_var  in: &src ";
         run;
         title;


         ods proclabel="Any missing for &local_var variable in: &src";
         proc print data=work.tmpy_&sysjobid  noobs width=uniform;
         where percent lt 0;
         var &local_var  count;
         title "Number of Missing: &local_var variable  in: &src ";
         run;
         title;

     %end; *** end of do loop;

         %delworksrc();


%mend;  ****************** end macro;



%macro field_freq(inds=,vartochk=);
         data _null_;
             src_scan=scan("&inds",2,'.');
             call symput('src',src_scan);
         run;

         %mkworktsrc;

     %let dschk_cnt = %sysfunc(countw(&vartochk, ' '));
     %do ggg = 1 %to &dschk_cnt;
         %let local_var = %scan(&vartochk, &ggg);

         ods proclabel="Freq of &local_var in &src";
         proc freq data=work.tmpz_&sysjobid;
         title "Freq of &local_var in &src";
             table &local_var  /nocol norow ;
         run;
         title;

     %end; *** end of do loop;

         %delworksrc();

%mend;  *************end macro;




%macro field_freqdt(inds=,vartochk=);
         data _null_;
             src_scan=scan("&inds",2,'.');
             call symput('src',src_scan);
         run;

         %mkworktsrc;

     %let dschk_cnt = %sysfunc(countw(&vartochk, ' '));
     %do ggg = 1 %to &dschk_cnt;
         %let local_var = %scan(&vartochk, &ggg);

         ods proclabel="Freq of &local_var in &src";
         proc freq data=work.tmpz_&sysjobid ;
         title "Freq of &local_var in &src";
             table &local_var  /nocol norow ;
             format &local_var yymon8.;
         run;
         title;

     %end; *** end of do loop;

         %delworksrc();

%mend;  *************end macro;




/* this will check amount fields to see get basic info on them */
%macro field_numbers(inds=,vartochk=);
      data _null_;
           src_scan=scan("&inds",2,'.');
           call symput('src',src_scan);
      run;

          %mkworktsrc;

      %let dschk_cnt = %sysfunc(countw(&vartochk, ' '));
      %do ggg = 1 %to &dschk_cnt;
          %let local_var = %scan(&vartochk, &ggg);


          data work.tmpy_&sysjobid;
              set work.tmpz_&sysjobid  (keep= &local_var);
              length validation $35.;
              validation="&local_var";
              audit=&local_var;
              drop &local_var;
          run;

          proc summary data=work.tmpy_&sysjobid  nway noprint;
              class validation;
              var   audit;
              output out=work.tmpy_&sysjobid  (drop=_type_ _freq_)
                           n=cnt_distinct_values
                           min(audit) =min
                           max(audit) =max
                           mean(audit)=mean
                           std(audit) =stdv
                           p10(audit) =p10
                           p25(audit) =p25
                           p50(audit) =p50
                           p75(audit) =p75
                           p90(audit) =p90
                           ;
          run;

          ods proclabel="Validation of &local_var in: &src";
          proc print data=work.tmpy_&sysjobid  width=uniform;
              title1 "validating: &local_var  variable  in: &src - &inds";
              title2 "numeric field stats";

          run;
          title;


      %end; *** end of do loop;

          %delworksrc();

%mend; ************ end macro;


%macro code_example();

%let LOW_VOL_THRESHOLD = 10;   /* set to 10 for VRDC downloads */

proc format;
    /* Default is to scrub values 10 or fewer */
    value scrub
       0-&LOW_VOL_THRESHOLD. = -999
       other=[12.0]
       ;
run;

/* Format the freq output to allow scrubbing. */
proc template;
    edit base.freq.OneWayList;
        edit Frequency;
           format=scrub.;
        end;
    end;
    edit base.freq.CrossTabFreqs;
        edit Frequency;
            format=scrub.;
        end;
    end;
run;


proc freq data=sashelp.baseball;
    table team /list missing nocum ;
run;


/* clean up template */
proc template;
    delete base.freq.CrossTabFreqs;
    delete base.freq.OneWayList;
run;

%mend;