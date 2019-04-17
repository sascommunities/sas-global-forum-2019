/**************************************************************************************************************\
*
* Copyright(c) 2019 SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
*
* Name: SGF Sample Case - Sending Employees EOY Compensation Statements
*
* Purpose: Send each company employee a compensation statement outlining compensation summary and/or changes
*
* Author: Salma Ibrahim
*
\**************************************************************************************************************/

/* Set libnames for employee dataset locations */
libname employee "C:\Users\YOURUSER\Desktop\SGF_SAS_Datasets";

/* Define set macros */
%let year=%eval(%sysfunc(year(%sysfunc(today())))-1);
%put &year;

/* Create a table of email addresses that don't meet minimal specs */
data employee.invalidsyntax;
	set employee.contact;
	if find(email,'@','i') ge 1 and find(email,'.','i') ge 1 and 
	length(email) >= 7 then delete;
run;

/* Scan log for bad email error message, output log line */
data error;
	infile  "C:\Users\YOURUSER\Desktop\SGF_Reports\logs\sendemails.log" truncover;
	input email_error $200.;
	if index(email_error, 'WARNING: Bad e-mail address:') > 0 or
	index(email_error, 'ERROR: Email:') > 0
	then output;
   run;

/* Scan each log line for email address that caused error */
data error ;
	set error;
	email=scan(email_error,-1," ");
run;

/* Sort errored emails table and contact table, then merge errored emails with employee's contact information for employee details */
proc sort data=error; by email; run;

proc sort data=employee.contact out=mergecontact; by email; run;

proc sql;
	create table errorlog as
	select mergecontact.*
	from error left join mergecontact
	on error.email=mergecontact.email;
run;

/*Sort and remove duplicates */
proc sort data=errorlog nodupkey;
	by employee_number;
run;

/* Scan log for successful email sent message, output line below message containing email */
 data success;
	infile  "C:\Users\YOURUSER\Desktop\SGF_Reports\logs\sendemails.log" truncover;
		input email_sent $100.;
	if index(email_sent, 'Message sent') > 0
	then do;
	count = 2;
	do until (count=0);
	output;
	count=count-1;
	if count = 1 then input email_sent $100.;
	end;
	end;
run;

/* Extract email address from log line */
data success (drop=email_sent count);
   set success;
   if email_sent="Message sent" then delete;
   email_sent=compress(email_sent,'"');
   email=substr(email_sent,14,-1);
   run;

/* Sort successful sends table and merge with employee contact table for more elaborate log of employee emails sent */
proc sort data=success; by email; run;

proc sql;
	create table successlog as
	select mergecontact.*
	from success left join mergecontact
	on success.email=mergecontact.email;
run;

/*Sort and remove duplicates */
proc sort data=successlog nodupkey;
	by employee_number;
run;

/* Export excel file of each summary table */
ods excel file="C:\Users\YOURUSER\Desktop\SGF_Reports\Syntax_Check_&year..xlsx";
proc print data=employee.invalidsyntax;
title "Invalid Email Syntax in Employee Dataset";
run;
   ods excel close;

ods excel file="C:\Users\YOURUSER\Desktop\SGF_Reports\SENT_TODAY_&year..xlsx";
proc print data=successlog;
title "Reports Successfully Sent Today";
run;
ods excel close;

ods excel file="C:\Users\YOURUSER\Desktop\SGF_Reports\INVALID_EMAIL_&year..xlsx";
proc print data=errorlog;
title "Errors Due to Invalid Email";
run;
ods excel close;

/* Send out email of summary reports to self */
options emailsys=smtp;
options emailport=25;
options emailauthprotocol=NONE;
options EMAILHOST="YOURMAILHOST";
filename outbox EMAIL;

data _null_;
FILE outbox
to=("YOUREMAILADDRESS")
importance="HIGH"
subject="Summary Report for Sending Employee Compensation Reports"
attach=("C:\Users\YOURUSER\Desktop\SGF_Reports\Syntax_Check_&year..xlsx"
"C:\Users\YOURUSER\Desktop\SGF_Reports\SENT_TODAY_&year..xlsx"
"C:\Users\YOURUSER\Desktop\SGF_Reports\INVALID_EMAIL_&year..xlsx");
file outbox;

put "Please see attached a summary of all reports that were sent
 out today, and a report of errors due to email addresses that are invalid.";
put;
put "Failed sends will need to be investigated and/or sent manually.";
put;
run;
