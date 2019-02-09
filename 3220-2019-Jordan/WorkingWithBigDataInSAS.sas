%let path=s:/workshop;
libname db teradata server=&TDServer user=&TDUser password=&TDPassword
        database=&TDDatabase multistmt=yes dbcommit=20000;
libname sas "&path";
%include "&path/cre8data.sas";

options sastrace=',,,d' sastraceloc=saslog nostsuffix;

/* Retrieves thousands of rows to be subset in SAS */
proc sql;
select customer_id
      ,customer_name
   from db.big_customer_dim
   where scan(customer_name,1) ='Silvestro' 
;
quit;

/* ANSI SQL LIKE operator allows subsetting in the DBMS, retrieves only 1 row */
proc sql;
select customer_id
      ,customer_name
   from db.big_customer_dim
   where customer_name like 'Silvestro%' 
;
quit;

/* ANSI SQL LIKE operator works for the DATA step too */
data _null_;
   file print;
   set db.big_customer_dim (keep=customer_id customer_name);
   where customer_name like 'Silvestro %' ;
   put customer_id customer_name;
run;


/*Summarizing data*/
/* Data step does it, but it's very slow */
data summary_data;
   set db.big_order_fact (keep=customer_id Total_retail_price);
   by customer_id;
   if first.customer_id then do;
      Items=0;
      Value=0;
   end;
   Count+1;
   Value+Total_Retail_Price;
   if last.customer_id then output;
   keep customer_ID Count Value;
run;

/* PROC MEANS generates SQL to do most of the work in-database - much faster!! */
proc means data=db.big_order_fact noprint;
   class customer_id;
   output out=summary_means(drop=_: where=(Customer_ID is not missing)) n=Count sum=Value;
   var Total_retail_Price;
run;

/* This ASNI query in PROC SQL goes straigh in-database - faster still!! */
proc sql;
create table summary as 
select customer_id
      ,count(*) as Count
      ,sum(Total_retail_price) as Value
   from db.big_order_fact
   group by customer_id
;
quit;

proc ds2;
data db.debt /overwrite=yes;
   dcl int Year;
   dcl decimal (38,2) Debt;
   method init();
      year=1976; debt=620387900876.52n;output;
      year=1986; debt=2125302616658.42n;output;
      year=1996; debt=5224810939135.73n;output;
      year=2006; debt=8506973899215.23n;output;
      year=2016; debt=18900932690017.04n;output;
      year=2018; debt=20492598761860.61n;output;
   end;
   method term();
      dcl decimal (38,2) diff diff_avg;
      diff=20492598761860.61n-8506973899215.23n;
      diff_avg=diff/12;
      put diff= diff_avg=;
      diff_avg=diff/11;
      put diff= diff_avg=;
   end;
enddata;
run;
quit;
/*Average increase 2006-2018 is 866163232566.82*/
/*diff=11985624862645.38 diff_avg=998802071887.12*/
/*diff=11985624862645.38 diff_avg=1089602260240.49*/

proc ds2;
data db.debt_ds2/overwrite=yes;
   dcl int Year;
   dcl decimal (38,2) debt increase;
   method init();
      year=                 2006;
      debt=    8506973899215.23n;
      increase= 998802071887.12n;
      output;
      do year=2007 to 2018;
        debt=debt+increase;
        output;
      end;
   end;
enddata;
run;
quit;

data db.debt_data_step;
   year=                 2006;
   debt=    8506973899215.23;
   increase= 998802071887.12;
   output;
   do year=2007 to 2018;
     debt=debt+increase;
     output;
   end;
run;


proc ds2;
data;
   dcl int Year;
   dcl decimal (38,2) debt increase;
   method run();
     set db.debt_ds2;
     by year;
   end;
enddata;
run;
quit;
