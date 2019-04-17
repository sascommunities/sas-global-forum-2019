/**************************************************************
Program: Code_For_SQL_How_SGF_2019 Lavery
programmer: r lavery
date: 2018/02/28
Purpose: code for attendees to run and modify in SQL How
**************************************************************/
/*
Topics are: 
Section A 1 OF 11) THE SAS DATA ENGINE          `       
Section B 2 OF 11) INDEXING
Section B 3 OF 11) THE SQL OPTIMIZER AND IMPROVING PERFORMANCE
Section D 4 OF 11) SUB-QUERIES: CORRELATED AND UNCORRELATED
Section E 5 OF 11) PLACEMENT OF SUB-QUERIES IN SQL SYNTAX
Section F 6 OF 11) VIEWS                            
Section G 7 OF 11) FUZZY MERGING
Section H 8 OF 11) COALESCING                       
Section I 9 OF 11) FINDING DUPLICATES
Section J 10 of 11) REFLEXIVE JOINS
Section K 11 of 11) USE SQL DICTOINARY TABLES TO DOCUMENT DATA SETS IN HYPERLINKED EXCEL WORKBOOK
*/


/****Section: Data Set Creation *************************/
Options msglevel=i;
ODS Listing;
ODS HTML close;
options nocenter MCompilenote = all;


PROC SQL;   create table MySchool
  ( Name Char(8) , Sex Char(1) ,  age  num 
   ,  Height  num , weight  num
   );
insert into MySchool
values('Joy'    ,'F', 11 , 51.3  , 50.5)
values('Jane'   ,'F', 12 , 59.8  , 84.5)
values('Jim'    ,'M', 12 , 57.3  , 83.0)
values('Alice'  ,'F', 13 , 56.5  , 84.0)
values('Jeff'   ,'M', 13 , 62.5  , 84.0)
values('Bob'    ,'M', 14 , 64.2  , 90.0)
values('Philip' ,'M', 16 , 72.0  ,150.0);

PROC SQL;   create table ExtraInfo
   (  Name Char(8) , age num, Sex Char(1)      
   , Allerg Char(4),  Diet Char(6) , sport num ,  ResDay Char(8) 
    );
insert into ExtraInfo 
values('Joy'   , 11 ,'F', 'None', 'Vegan'   , 3  ,'Resident')
values('Jane'  , 12 ,'F', 'Nuts',  'Meat'   , 1  ,'Day')
values('Jim'   , 12 ,'M', 'None',  'Meat'   , 0  ,'Resident')
values('Alice' , 13 ,'F', 'Nuts',  'NoMeat' , 1  ,'Resident')
values('Jeff'  , 13 ,'M', 'Dust',  'Vegan'  , 1  ,'Day')
values('Philip', 16 ,'M', 'None',  'NoMeat' , 2  ,'Resident');
quit;

/*******************************************************************************************/
/** Section A- 1 of 11: THE SAS DATA ENGINE ******/
/*  The fact that different numbers of observations were read supports the idea 
     that a data engine exists that is close to the hard drive.*/
/*******************************************************************************************/
/*Example A_1*/
Data A01_IF_example ;
   /*Reads 19 obs*/
   set sashelp.class ;
   if sex NE "F";
   run;


Data A02_Where_Example ;
   set sashelp.class ;
   /*Reads 10 obs*/
   Where sex NE "F";
   run;


/*******************************************************************************************/
/** Section B - 2 of 11: INDEXING**/
/*******************************************************************************************/
/*Example B_1 run in small steps and look for notes in the log*/
PROC SQL;
/*Create a dataset on which you can create an index*/
Create table B01_MyClass 
 as select * 
 from SASHelp.class;
/*Data set B01 has an index created by SQL, B02 will create the index using a data step*/
Create index name on B01_MyClass(name);

PROC Contents data=B01_MyClass centiles;
Title "Example B_1 The PROC Contents tells you about indexes";
TITLE2 "but it does not tell you much - read Mike Raithal's paper";
run;
title "";


PROC SQL;
Select * 
 /*B_01_A: No note in log*/
 from B01_MyClass;

Select * 
 from B01_MyClass
/*B_01_B: There is a note in the log
 INFO: Index Name selected for WHERE clause optimization*/
 where name="Jane";


Select * 
 from B01_MyClass
/*B_01_C: There is a note in the log
 INFO: Index Name selected for WHERE clause optimization*/
 where substr(name,1,1)="J";

 Select * 
 from B01_MyClass
/*B_01_D: There is a note in the log
 INFO: Index Name selected for WHERE clause optimization*/
 where substr(name,2,1)="o";

 Select * 
 from B01_MyClass
 /*B_01_E: No Note in log (violates the 10% rule?)*/
 where substr(name,2,1)in ("a","e","i","o","u");

 Select * 
 from B01_MyClass
 /*B_01_F: No note in log - we did not have an index on age*/
 where age=13;

/*Only Difference between B01 and B02 is that the index for Data B02 was created in a data step - B01 used SQL*/
/*Example B_2 Run code in steps and look for notes in the log - resuilts will match B01*/
Data B02_My_Class(index=(name));
 set SASHelp.class;
 run; 

PROC Contents data=B02_My_Class centiles;
Title "Example B_2 The PROC Contents tells you about indexes";
TITLE2 "but it does not tell you much - read Mike Raithal's paper";
run;
title "";

Data _null_;
 set B02_My_Class;
 /*No Where -- No INFO in log. SAS Reads ALL 19 obs*/
 run;

Data _null_;
 set B02_My_Class;
 /*INFO: Index Name selected for WHERE clause optimization. is in log*/
 where name="Jane";
 run;
 
 Data _null_;
 set B02_My_Class;
 /*INFO: Index Name selected for WHERE clause optimization. is in log*/
 where substr(name,1,1)="J";
 run;

 Data _null_;
 set B02_My_Class;
 /*INFO: Index Name selected for WHERE clause optimization. is in log*/
  where substr(name,2,1)="o";
  run;
 
Data _null_;
 set B02_My_Class;
 /*No Note in log (violates the 10% rule?)*/
    where substr(name,2,1)in ("a","e","i","o","u");
 run;

Data _null_;
 set B02_My_Class;
 /*NO INFO in log, but reads 3 obs*/
    where age=13;
 run;
title "";


/*******************************************************************************************/
/** Section C - 3 of 11: THE SQL OPTIMIZER AND IMPROVING PERFORMANCE **/
/*******************************************************************************************/
/*Example C_1 run this and look in the log. 
   The log will show a summary for the program that the optimizer plans to run*/
PROC SQL _method _tree;
title "Example C_1 Look in Log to see the explain plan. The output from _method and _Tree";
 select name    from sashelp.class
   where sex="M"     
    order by Age;
title "";

/*******************************************************************************************/
/** Section D - 4 OF 11) SUB-QUERIES: CORRELATED AND UNCORRELATED*/
/*******************************************************************************************/
/*Example D_1*/
PROC SQL _method _tree;
  Title "Example D_1 UNcorrelated Sub query in the FROM clause";
  Select * 
  From  (Select name , sex , height 
           from MySchool as I
           where I.sex='F');
title "";

/*Example D_2*/
PROC SQL _method _tree;
  Title "Example D_2 UNcorretated Sub query in the WHERE clause";
  Select name , sex, age 
  From MySchool as O
  Where O.Sex=
    (select sex 
      from ExtraInfo 
      having Sport=max(Sport)
    );
title "";

/*Example D_3*/
PROC Sql;
  Title "Example D_3 use join to replace UNcorretated Sub query in the FROM clause";
  select name , Outer.sex, age 
  from 
     MySchool as Outer
  Inner join
    (select sex 
     From ExtraInfo 
     having Sport=max(Sport)
     ) as sub
  on Outer.sex=sub.sex;

/*Example D_4*/
PROC SQL;
  Title "Example D_4 Correlated Sub query in the Where clause";
  select name , sex, age 
  from MySchool as O
  where O.Age =
    (select Age from ExtraInfo as I
       Where I.sex EQ O.Sex 
       Having Sport=Max(sport)
     );
title "";

/*Example D_5*/
/*Correlated query vs Join*/
PROC SQL;
/*This is a correlated query in the WHERE clause ** note I.sex  NE O.Sex */
  Create table D05_Corr_Sub_Q as 
  Select name , sex, age 
  From MySchool as O
  Where EXISTS 
    (select * from ExtraInfo as I   
      having  I.age  = O.age 
      and I.sex  NE O.Sex
     ) ;

PROC SQL;
  /*This is a join query" ** note inner join */
  Create table D05_Equivolent_Join as
  Select O.name , O.sex, O.age 
  From 
     MySchool as O
  Inner join
     (select name, sex, age 
       from ExtraInfo 
      ) as WasSub
  On O.Age=WasSub.Age
     and O.sex NE WasSub.sex;

 PROC compare base=D05_Corr_Sub_Q compare =D05_Equivolent_Join;
 title "Example D_5 This compares the resuolts from the correlated query and the join";
 run;
title "";

/*******************************************************************************************/
/** Section E 5 OF 11) PLACEMENT OF SUB-QUERIES IN SQL SYNTAX **/
/*******************************************************************************************/
/*Example E_1*/
PROC SQL; 
  title "Example E_1 Subquery returns a 1 BY 1 to one 'cell' as SQL processes EACH ROW in the Select";
  title2 "Exploring what shapes of data can be returned to what parts of a SQL Query";
  select O.name, O.age
 ,(select I.age 
    from ExtraInfo I 
    where Name='Joy') as Age_of_Joy
 , O.sex
    From MySchool as O;
title "";

/*Example E_2 INTENTIONAL FAIL*/
PROC SQL; 
  title "Example E_2  Subquery returns A COLUMN OF DATA to one 'cell' as SQL processes EACH ROW in the Select";
  title2 "Exploring what shapes of data can be returned to what parts of a SQL Query";
  select O.name
        , O.age  
        ,(select DISTINCT I.age 
            from ExtraInfo I) as Returns_col 
        , O.sex
  From MySchool as O; 
title "";

/*Example E_3 INTENTIONAL FAIL*/
PROC SQL;
  title "Example E_3 Subquery returns MULTIPLE ROWS to one 'cell' as SQL processes EACH ROW in the Select";
  title2 "Exploring what shapes of data can be returned to what parts of a SQL Query";
  select O.name
       , O.age 
      /*Subquery returns multiple vars TO EACH ROW - in the Select*/
      ,(select I.name, I.Sex, I.sport 
          from ExtraInfo as I
          where name='Joy') as Mult_Vars
       , O.sex
From MySchool as O; 
title "";

/*Example E_4 INTENTIONAL FAIL*/
PROC SQL; 
  title "Example E_4 Subquery returns A TABLE to one 'cell' as SQL processes EACH ROW in the Select";
  title2 "Exploring what shapes of data can be returned to what parts of a SQL Query";
  select O.name
    ,O.age 
    /*Subquery returns a table - in the select*/
    ,(select I.age , I.diet , I.sport   
      from ExtraInfo as I)
     , O.sex 
     From MySchool as O; 
title "";

/*Example E_5*/
/* Shapes allowed in the Where and having*/
PROC SQL;  
  title "Example E_5 UNcorrelated Subquery returns A 1 by 1 to the Where";
  title2 "Exploring what shapes of data can be returned to what parts of a SQL Query";
  select *  
   From MySchool as O
   /*UNCoirrelated Subquery returns 1 by 1 in the Where or Having*/
     where O.Age LE 
        (Select MAX(I.age) 
         from ExtraInfo as I
         );
title "";

/*Example E_6*/
PROC SQL;  
  title "Example E_6 UNcorrelated Subquery returns A COLUMN of data to the Where";
  title2 "Exploring what shapes of data can be returned to what parts of a SQL Query";
  select O.* 
   From MySchool as O
     /*Subquery returns column - in the Where or Having*/
     where O.Age IN 
      (Select distinct I.age 
        from ExtraInfo  as I
       );
title "";

/*Example E_7*/
PROC SQL;  
  title "Example E_7 Correlated Subquery returns A ROW of data to the Where";
  title2 "Exploring what shapes of data can be returned to what parts of a SQL Query";
  title3 "if you are in MySchool AND in ExraINFO, you show up ";
  title4 "We lose Bob";
   select O.* 
   From MySchool as O
   /*Subquery returns column - in the Where or Having*/
   where  Exists
          (Select I.Name, I.sex, I.sport 
          from ExtraInfo as I 
          where O.name=I.name
          );
title "";

/*Example E_8*/
Proc SQL;  
  title1 "Example E_8 Correlated Subquery returns A TABLE of data to the Where";
  title2 "Exploring what shapes of data can be returned to what parts of a SQL Query";
  title3 "There is one or more people in ExtraInfo of the same sex - you show up in the report";
    select *  
    From MySchool as O
    /*Subquery returns table - in the Where or Having*/
    where Exists 
        (Select I.*
         from ExtraInfo as I 
         where I.sex= O.sex
        ); 
title "";

/*******************************************************************************************/
/** Section F - 6 OF 11) Views**/
/*******************************************************************************************/
/*Example F_1 Show Views being used*/
Proc SQL;
Create View F1_Old_guys as
select name, sex, age
    , Weight/2.2 as Wt_KG
from SAShelp.class as c
where sex='M' and age > 13;

proc print data=F1_Old_guys; run;
title "xample F_1 Show Views being used";
run;
title "";

/*Example F_2 Show Views being used*/
PROC Gchart data=F1_Old_guys;
title "Example F_2 Show Views being used";
pie age /discrete; run;

PROC Univariate data=F1_Old_guys;
var age; run;
title "";

/*Example F_3 Views being chained*/
PROC SQL;
  create VIEW F3_boys as
  select * from sashelp.class
  where sex='M';

PROC SQL;
  create VIEW F4_Old_boys as 
  select * from F3_boys
  where age GE 14;

PROC SQL;
  CREATE TABLE F05_Chained_Views as
/*"This is the result of chained views";*/
/*"Note that the log only shows one data set being created";*/
select 
  'number of old boys' as tag
  ,count(*) as Nmbr_old_boys
from F4_Old_boys
;
QUIT;

PROC PRINT data=F05_Chained_Views;
title "Example F_3 Views being chained This is the result of chained views";
title2 "Note that the log only showed one data set being created when we created F01_Chained_Views";
run;

/*Example F_4 table vs view*/
/*Show the diifference between a table of data and a view of data*/
PROC SQL;
  Create table F06_Class_table as 
  select * 
  from SASHelp.class;

  /*Use the SQL command "Describe" to see "what is in" F02_Class_table..Data */
  Describe table F06_Class_table; 


PROC SQL;
  Create view F06_Class_View as 
  select * 
  from SASHelp.class;

  /*Use the SQL command "Describe" to see "what is in" F02_Class_View..INSTRUCTIONS */
  DESCRIBE VIEW F06_Class_View;



/*Example F_5  Making a perm View - handling the libname issue*/
/*The View ITSELF must contain a libname because not evey user uses the same libnames*/
options noxsync noxwait;
x "mkdir C:\temp";            /*Make a dir*/
x "mkdir C:\Perm_Views";      /*Make a dir*/

Libname OneSpot "C:\temp";    /*define libraries to the session*/
Libname ViewLoc "C:\Perm_Views";

/*Place some data in C:\temp
  at a place that the SAS session thinks of as OneSpot*/
Data OneSpot.F03_Class_data;
set SASHelp.Class; run;


Proc SQL ;
/*"This is a Permanent view so has a two part name";*/
 Create view  ViewLoc.F04_Eng_2_Met    as
    select   name  
            ,Weight/2.2 as Wt_Kg 
            ,height*2.25 as Hgt_cm
    from PermLoc.F03_Class_data
        /*Get some data From C:\temp
        A place that the View thinks of as PermLoc*/    
       using libname PermLoc 'C:\TEMP';
quit;

PROC Print data= ViewLoc.F04_Eng_2_Met;
title "Example F_5  Making a perm View This is a Permanent view so has a two part name";
run;
title "";





/*******************************************************************************************/
/** Section G - 7 OF 11) FUZZY MERGING */
/*******************************************************************************************/
/* Misspelling of names is very common
   We have purchased physican information from two different sources (two conferences) 
    and want to find peopel who attended both conferences.
    We will match on name and other characteristics  */

/*Example G_1  Fuzzy merging is common when you have to match up names and addresses*/
Data G01_Doctors_2010;
Infile datalines truncover firstobs=4;
input @1  name $Char15.
      @17 City $Char6.
      @25 BrdCert $Char3.; /*BrdCert = board certified*/
datalines;
Name    CITY  Board Cert.
         1         2         3
123456789012345678901234567890
Dr. Sebastian   Paris   YES  
Dr. O'Banion    Dublin  YES  
Dr. Jaramillo   Madrid  YES  
Dr. Mafume      Tokyo   YES  
Dr. Lu          Boston   NO 
;run;

Data G02_Doctors_2011;
Infile datalines truncover firstobs=1;
input @1  name $Char15.
      @17 City $Char6.
      @25 BrdCert $Char3.;
datalines;
Dr. Sebastian   Paris   YES
Dr. O'Banionn   Dublin  YES
Dr. Jaramillo   Madr d  YES
Dr. Mafumee     T kyo   yES
Dr. Lu          Boston   NO
;run;

Proc SQL; 
  title "Example G_1  Fuzzy merging"; 
  select    ( (O.name=N.name)        *9
              +(O.City=N.City)       *5
              +(O.BrdCert=N.BrdCert) *3  /*BrdCert = board certified*/
             ) as score
        /* O stands for Old=2010 and N stands for New=2011*/
            ,O.name as Old_N , O.city as Old_C , O.BrdCert as OBC 
            ,N.name as New_N , N.city as New_C , N.BrdCert as NBC 


        from G01_Doctors_2010 as O , G02_Doctors_2011 as N
        having score >= 2   order by score desc ,O.name  ;
title "";

/*Example G_2  use a format to make the Fuzzy merging results more readable*/
Proc format ;
value Mtching
17="Name & City & Board"
12="Name & Board"
8="City & Board"
9="Name"
5="City"
3="Board only"
0="no Match";run;

Proc SQL;   
  title "Example G_2  Fuzzy merging w format"; 
select ((O.name=N.name)*9
         +(O.City=N.City)*5
        +(O.BrdCert=N.BrdCert)*3) 
            as score format=Mtching.
        /* stands for Old-2010 and N stands for New=2011*/
        ,O.name as ON , O.city as OC ,O.BrdCert as OBC 
        ,N.name as NN , N.city as NC ,N.BrdCert as NBC 
    from G01_Doctors_2010 as O , G02_Doctors_2011 as N
    having score >= 2   order by score desc ,O.name;
quit;
title "";

/*******************************************************************************************/
/** Section H - 8 OF 11) COALESCING  **/
/*******************************************************************************************/
/*Example H_1 missing values protagate and make report look bad 
 Using a coalesce to replace missings with zeros*/
Proc SQL;
create table H01_Nm_money 
( name char(4)
 ,balance  num ); 

insert into H01_Nm_money 
 values('russ' ,  .  )
 values('joe' ,10000)
 values('Chi' ,60000)
;

Proc SQL;/*INTENTIONAL ERROR*/
  create table H02_interest1 as
  select 
    name
    , coalesce(balance,0) as balance2 
    , balance2*.05 as interest1 /*INTENTIONAL ERROR*/

  From H01_Nm_money;
quit;/*INTENTIONAL ERROR*/

/*Example H_2 missing values propagate and make report look bad 
 Using a Calculated to fix problem*/
Proc SQL;
  create table H02_interest3 as
  select 
    name
    , coalesce(balance,0) as balance2 
    , calculated balance2*.05 as interest

  From H01_Nm_money;
quit;

PROC Print data=H02_interest3;
  title "Example H_1 Using a coalesce to replace missings with zeros";
run;
title "" ;

/*Example H_3 A Coalescing issue Russ is spelled differently and the coalesce does not work*/
PROC SQL;
  create table H05_Nm_job_Mismatch 
  ( name char(4)
   ,job  char(5) ); 

insert into H05_Nm_job_Mismatch 
  values('Russ','Geek')
  values('Joe' ,'Prgmr')
  values('Chi' ,'Mgr.')
;

PROC SQL;
  create table H06_Nm_Time 
  ( name char(4)
   ,Time_W_Co num ); 

insert into H06_Nm_Time
  values('russ',6)
  values('Chi' ,8)
;

Proc SQL;
 Create table H07_name_Job_Time_Mismatch as
 Select 
    coalesce (J.name,T.name) as name
    ,j.job as job
    ,coalesce(T.Time_W_Co, 0) as time_w_co

  From 
     H05_Nm_job_Mismatch as J
       left join
     H06_Nm_Time as T
  On j.name=t.name;
    ;

Proc print data=H07_name_Job_Time_Mismatch;
  title "Example H_2 A Coalescing issue Russ is spelled differently and the coalesce does not work";
run;

/************************************************************/
/*Example H_4 Using a coalesce to get the most recent data*/
/*We have three Years of donation data and want most recent info (people have an ID*/
Data H08_Yr2006;
 infile datalines truncover 
  firstobs=3;
  input @1 ID 
        @5 Name   $char6.
        @15 state $char6.;  
Datalines;
ID  Name      State  
12345678901234567890
001 Robert    TN2006
002 Calvin    NH2006
005 Carl      NJ2006
007 Earl      NY2006
008 Ell       DE2006
025 Ted       WI2006
;
run;

data H09_Yr2005;
infile datalines truncover 
  firstobs=3;
input @1 ID 
      @5 Name   $char6.
      @15 state $char6.;  
Datalines;
ID      Name        State  
12345678901234567890
001 Bob       PA2005
002 Cal       NH2005
005 Carl      NJ2005
006 Errol     CA2005
020 Sue       NJ2005
;
run;

data H10_Yr2004;
infile datalines truncover 
     firstobs=3;
input @1 ID 
      @5 Name $char6.
      @15 state $char6.;  
Datalines;
ID      Name        State  
12345678901234567890
001 Bob       PA2004
005 Carl      NJ2004
010 Fan       DE2004
011 Mike      PA2004 
;

Proc SQL;
create table H11_current as
 select
  coalesce(six.ID   ,Five.ID    ,Four.ID)    as Coalesced_ID
 ,coalesce(six.name ,Five.name  ,Four.name)  as Most_recent_name
 ,coalesce(six.State,Five.State ,Four.State) as Most_recent_Add
 
from H08_yr2006 as six
  full join 
     H09_yr2005 as five on six.id=five.ID
  full join
     H10_yr2004 as four on (four.ID=six.ID or four.id=five.id)
   ORDER BY Coalesced_ID; 

PROC Print data=H11_Current;
  title "Example H_3 Using a coalesce to get the most recent data";
run;
title "";

/*******************************************************************************************/
/** Section I - 9 OF 11) FINDING DUPLICATES **/
/*******************************************************************************************/
/* This is a very useful, and fairly simple, bit of SAS code */
/*Example I_1  Flexible way of finding and a easily understood reporting on duplicates*/
Data I01_DataW_duplicates;
infile datalines truncover firstobs=4  ;
input @1  name   $Char6. 
      @9  Sex    $char1.
      @13 Age         2.
      @17 height    4.1
      @25 Weight    5.1
      ;
datalines ;
Name  Sex  Age  Height Weight
         1         2         3         4         5 
12345678901234567890123456789012345678901234567890
Jane    F    .   59.8    84.5
Alfred  M   14   69.0   112.5
Carol   F   14   62.8   102.5
Fred    M   12   57.3    83.0
Jane    F   12     .       .5
Alfred  M   99   69.0   112.5
Louise  F   12   56.3    77.0
Jane    F   12   59.8    84.5
;
run;

PROC SQL;
title "Example I_1  Flexible way of finding and a easily understood reporting on duplicates";
 select I01_in.Number_Of_Dupes
       ,I01_Out.*
 from  
  I01_DataW_duplicates as I01_Out
   inner join
  (select name, sex, count(*) as Number_Of_Dupes
    from I01_DataW_duplicates 
    group by name, sex
      having Number_Of_Dupes >1)  as I01_in 
      on I01_in.name=I01_Out.name
       and I01_in.sex=I01_out.sex
   order by Number_Of_Dupes desc , name, sex;
title "";

/*******************************************************************************************/
/** Section J - 10 of 11) REFLEXIVE JOINS **/
/*******************************************************************************************/
/*This is the classic example of using a reflexive join to find a person's boss*/
/*Example J_1  The common reflexive join*/
PROC SQL;
/*Here is the data set - the ida is to */
create table J01_employees 
          (EmpNo    num
           ,job    char(15)
           ,name   char(15)
           ,SupervisorEmpNo num
          );
insert into J01_employees 
values(1,  "1_Pres"            ,"Goodnight" ,.)
values(4,  "2_V.P. Sales"      ,"Kurd"      ,1)
values(6,  '2_V.P. R&D'        ,"Church"    ,1)
values(8,  "2_CFO"             ,"Lee"       ,1)
values(14, "3_Salesman"        ,"Wang"      ,4)
values(18, "3_Salesman"        ,"Rama"      ,4)
values(26, "3_Chemist"         ,"Levin"     ,6)
values(28, "3_Metalurgist"     ,"Klien"     ,6)
values(31, "3_Acntg. Mgr"      ,"Dowd"      ,8)
values(36, "3_Acntg. Mgr"      ,"Shu"       ,8)
;

Proc SQl;
Select empl.EmpNo
	 , empl.job
     , empl.name
	 , Rpt2.name as supervisor
	 , Rpt2.job as supv_job
from J01_employees as empl
   inner join 
     J01_employees as Rpt2
     on empl.supervisorEmpNo=Rpt2.EmpNo
order by supv_job;


/*Example J_2  Finding connecting flights to get you home********************/
proc SQl;
Title  "Example J_2  Finding connecting flights to get you from  LA home to Phila";
Title2 "Use a reflexive join to find the fastest epath through a network";
create table J02_Flights 
  (origin           Char(3)
  ,flight           num
  ,Destination      char(3)
  ,time         num);
insert into J02_Flights 
values("SFO",111,"CHI",240)   /*San Fran to Chicago*/
values("LAX",111,"CHI",210)   /*LA to to All Chicago*/
values("LAX",121,"NOH",220)   /*LA to Just  O'Hare*/
values("LAX",131,"CAK",266)   /*LA to Akron */
values("CHI",241,"PHL",145)   /*All Chicago to Philadelphia*/
values("NOH",201,"PHL",167)   /*O'Hare to Phila*/
values("CAK",201,"PHL",145)   /*Akron to Phila*/
values("CAK",201,"EWK",145);  /*Akron to Newark*/
;

proc SQL;
select  wc.origin as WCStart            /*West Coast Start airport*/ 
         ,  wc.flight as WCFlight       /*West Coast Flight*/ 
           , wc.time as WCTime          /*West Coast time*/
              , wc.Destination as WCEnd /*West Coast ending airport*/
       , "->" as spacer label="#"
       ,ec.origin as ReStart                /*East coast Start Airport*/ 
           ,ec.flight as ECFlight           /*East Coast Flight*/ 
              ,ec.time as ECTime            /*East Coast time*/
                  ,ec.Destination as ECEnd  /*East Coast ending airport*/
     ,  (ec.time+wc.time) as TotalTime      /*flying time*/
  from J02_Flights as wc  inner join  J02_Flights as ec
  on wc.Destination=ec.origin and WC.origin="LAX" and EC.Destination="PHL"
  order by totalTime desc;
title "";


/*******************************************************************************************/
/** Section K 11 of 11) USE SQL DICTIONARY TABLES TO DOCUMENT YOUR DATA SETS IN A HYPERLINKED EXCEL WORKBOOK*/
/*******************************************************************************************/
/********ONLY WORKS FOR SAS 9.4 tm3 - tm4 and tm5 need slightly different coding *********************/
%MACRO Check_by_VDG_V94_TM3(LibName=SASHelp /*<-- only use upper case letters*/
                 );
/*excel limit 1,048,576 rows by 16,384 columns*/
%local lp Libname FileList DateList NObsList SizeList Lenlist NOfVarslist;
%local            ThisFile ThisDate ThisNObs ThisSize ThisLen ThisNVar;
%let Libname=%UpCase(&LibName);
%put Libname=&Libname;

ods _all_ close;
%let path2lib = %sysfunc(pathname(&LibName));
ODS Excel File="E:\_2018_SAS_Global_Forum\Macros\Contents_of_&Libname..xlsx " 
           nogtitle nogfootnote style=HTMLBlue ;
ODS Excel options(embedded_titles='yes' embedded_footnotes='yes');

Proc SQL noprint /*inobs=10*/;
select memname , modate, nobs, filesize, obslen , NVar
  into  :filelist separated by " "
        ,:DateList separated by " "
        ,:NObsList separated by " "
        ,:SizeList separated by " "
        ,:Lenlist separated by " "
        ,:NOfVarslist separated by " "
 from Dictionary.tables
 /*Below will eliminate views and graphic data types*/
 where libname="&Libname" & MEMTYPE="DATA" and typemem ="DATA" and nobs GE 0;
%put filelist  = &filelist   ;
%put DateList  = &DateList   ;
%put NObsList  = &NObsList   ;
%put SizeList  = &SizeList   ;
%put Lenlist   = &Lenlist    ;
%put NOfVarslist=&NOfVarslist;

 /*this is the list of all the tables and goes on the first tab*/
ods Excel options(sheet_name="List_of_tables_in_lib" );
Proc report data=sashelp.vtable /*(obs=10)*/ nowd;
title "Tables in this library (&Libname) and workbook";
title2 "S=sorted ** SK= sorted with no duplicate key values ** SR - sorted with no duplicate records";
title3 "YES | CHAR= compresses (variable-length records) by SAS using RLE (Run Length Encoding). Compresses repeated comsiecutive characters.";

title4 "Binary=obs. compresses (variable-length records) by SAS using RLE (Run Length Encoding).";
 Column  ('Click MemName to see desired data' libname memname MEMTYPE modate typemem nobs filesize obslen NVar
                                              indxtype  sorttype  sortchar compress pcompress);
 compute memname;
     urlstring="#'"||strip(memname)||"'!A1";
    call define(_col_,'url',urlstring);
    call define(_col_,'style', 'style=[textdecoration=underline]');
 endcomp;
 where libname="&Libname" & MEMTYPE="DATA" and typemem ="DATA" and nobs GE 0;
run;quit;

/***/
ods Excel options(sheet_name="List_of_indexes_lib" );
Proc Report data=sashelp.vindex(obs=10) ;
title "Indeces in this workbook";
where libname="&Libname" & MEMTYPE="DATA" ;
run;quit;


/*Title    link="#'List_of_tables_in_lib'!A1" '(Click to return to list of tables (first tab))';*/
/*Footnote link="#'List_of_tables_in_lib'!A1" '(Click to return to list of tables (first tab))';*/

%let lp=1;
 %do %while(%scan(&filelist,&Lp) NE);
    %let ThisFile = %scan(&filelist,&Lp);
    %let ThisDate = %scan(&DateList,&Lp);
    %let ThisNObs = %scan(&NObsList,&Lp);
    %let ThisSize = %scan(&SizeList,&Lp);
    %let ThisLen  = %scan(&Lenlist,&Lp);
    %let ThisNVar = %scan(&NOfVarslist,&Lp);

    ods excel options(sheet_interval='table');
    ods exclude all;
       data _null_;
       declare odsout obj();
       run;

   ods select all;
   ods excel options(sheet_interval='none' sheet_name="&ThisFile" );


     title "&Libname &ThisFile: rows=&ThisNObs NVars=&ThisNVar ModDate=&ThisDate Size=&ThisSize Obslen=&ThisLen";
     Title    link="#'List_of_tables_in_lib'!A1" '(Click to return to list of tables (first tab))';
     Footnote link="#'List_of_tables_in_lib'!A1" '(Click to return to list of tables (first tab))';
     *footnote2 "&libname is: &path2lib and workbook" ;
    Proc Report data=sashelp.VColumn nowd;
       Column
         libname memname memtype name type length npos varnum label format informat
         idxusage sortedby xtype notnull precision scale transcode diagnostic ;
       where libname="&Libname" & MemName="&ThisFile";
       run;quit;

       title "&Libname &ThisFile: rows=&ThisNObs NVars=&ThisNVar :: SHOW ten obs" ;
       Proc print data=&Libname..&ThisFile(obs=10) ;
       run;quit;
       title "";

     %let Lp = %eval(&Lp+1);
%end; 
ods Excel Close;
%MEND Check_by_VDG_V94_TM3;

%Check_by_VDG_V94_TM3(Libname=SASHELP /*<-- only use upper case letters*/
           );











