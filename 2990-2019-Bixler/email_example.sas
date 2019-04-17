/* Assign Folders and Libraries */

%let macropath = \\pghsas02\Tools\SAS Macros;

data _null_;
%let syscc=0;
%let datetime_start = %sysfunc(DATETIME());
call symputx('ds',PUT(%sysfunc(DATETIME()),E8601DT23.3));
call symputx('tday',substr(put(today(), mmddyy10.),7,4)||"_"||substr(put(today(), mmddyy10.),1,2)||"_"||substr(put(today(), mmddyy10.),4,2));
%let process 	= SAS_Email_List;
%let when_run 	= Daily;
%let group 		= Informatics;
%let path 		= \\pghsas03\Production\Daily\Informatics_SAS_Email_Reports;
%let archive	= &path.\archive;
%let metrics	= \\pghsas03\Production\Metrics;
%let input		= \\pghsas03\Production\Email Distro;
run;

%let Rpt_Name= SAS_Email_Reports;

libname DATA "&path.\Data";
libname ARC "&archive.";

/* Macros and Dates*/

/* The below macro will turn a sas date into an oracle date for smooth reporting */ 
%include "&macropath.\SAS_Date_to_Oracle_Date.sas";
%macro to_oracle_date(sas_Date);

 %str(%') %Sysfunc( PutN( &sas_date. , date7. )) %str(%')

%mend to_oracle_date; 
/* The above macro will turn a sas date into an oracle date for smooth reporting */

/* The below macro compiles the Email Distribution list.
   This is where your macro &DISTRO comes from.          */
%include "&macropath.\SAS_Email_Distro_List.SAS";
%macro email_Distro;

libname EMAIL '\\pghsas03\Production\Daily\Informatics_SAS_Email_Reports\Data';

data email_2;
set EMAIL.active_sas_email;
where report="&Rpt_Name.";
To_Person=compbl("'"||trim(to)||"'");
run;

data Distro_List;
do until (last.Report);
set email_2;
by Report notsorted;
length Distro $32767;
Distro=catx('',Distro,To_Person);
end;
drop To_Person;
run;

data distro;
set Distro_List;
call symputx("Distro",Distro);
run;

%mend email_Distro;
/* The above macro compiles the Email Distribution list.
   This is where your macro &DISTRO comes from.          */

/* The below macro will setup the email to be sent when the 
   program is complete and the file is created that is
   ready to be sent                                         */
%include "&macropath.\SAS_Email_It.SAS";
%macro Email_It(TO,SUBJECT,ATTACH);
    
data _null_;
    file sendit email
	    from=("SASPROD@GATEWAYHEALTHPLAN.COM")
		to=(&TO.)
		subject=&ATTACH.;
		    put "Greetings - Today's Report is attached.";
			put;
			put "Thanks"
			put "SAS Reporting Team";
run;

%mend Email_It;
/* The above macro will setup the email to be sent when the 
   program is complete and the file is created that is
   ready to be sent                                         */

/* The below code will import the Centralized Report List 
   with the intended recipients on it and update it 
   with any additions                                     */
data dates;
metrics_name=compbl("&group." ||"_"|| "&Process.");
file_name=compbl("&Process."||"_"||"&tday.");
call symputx("File_Name",file_Name);
call symputx("metrics_name",metrics_name);
run;

/* Import the SAS Email Distro List */

PROC IMPORT
Datafile="&input.\SAS Email Distro.XLSX"
out=Current_Email_List
Dbms=excel replace;
run;

/* Archive the Current Version of the SAS Email List */

data arc.SAS_email_&tday.;
set data.Active_SAS_Email;
run;

/* Create New and Updated SAS Email List */

data data.Active_SAS_Email;
set current_email_list;
where report^='Test_Dummy';
run;
/* The above code will import the Centralized Report List 
   with the intended recipients on it and update it 
   with any additions                                     */

/* The below wraps up the entire concept. It is calling 
   the Email_It macro using the &DISTRO. macro variable 
   created in the Email_Distro macro, then sends out
   the email to the desired group                       */
%Email_It(&DISTRO.,SAS Email Distribution List Updated,"&input.\SAS Email Distro.XLSX");
/* The above wraps up the entire concept. It is calling 
   the Email_It macro using the &DISTRO. macro variable 
   created in the Email_Distro macro, then sends out
   the email to the desired group                       */

