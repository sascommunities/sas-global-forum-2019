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

/* Import CSVs of employee data */
proc import datafile="C:\Users\YOURUSER\Desktop\Employee_HR_Data.xlsx" out=employee.employee_data dbms=xlsx replace; run;

proc import datafile="C:\Users\YOURUSER\Desktop\Employee_Emails.xlsx" out=employee.email dbms=xlsx replace; run;

/* Define set macros */
%let year=%eval(%sysfunc(year(%sysfunc(today())))-1);
%put &year;

/* Create contact table for macro input */
proc sql;
create table employee.contact as
select email.*, cat(strip(employee_data.first_name)," ",strip(employee_data.last_name)) as name, employee_data.*
from employee.email left join employee.employee_data on
email.employee_number=employee_data.employee_number;
run;

/* Populate email recipients with your email address for testing purposes */
data employee.contact;
set employee.contact;
email="YOUREMAILADDRESS";
mgremail="YOUREMAILADDRESS";
deptmgremail="YOUREMAILADDRESS";
department=compress(department," ");
run;

/* Define macro to send employee compensation reports with additional options and simple report creation */
%macro sendreports(department,email,name,mgremail,deptmgremail,salary,increase,newsalary,bonus);

%put &department;
%put &email;
%put &name;
%put &mgremail;
%put &deptmgremail;
%put &salary;
%put &increase;
%put &newsalary;
%put &bonus;

/* Create simple report attachment to be attached in email below */
ods pdf file="C:\Users\YOURUSER\Desktop\SGF_Reports\&name._&department..pdf";
	title j=center bold "&name. &year. Employee Compensation Report";
	ods text= "Dear &name.: "; ods text=" ";
	ods text= "Please see below your salary increase and bonus information for &year.. Changes and bonus disbursement will take effect in your next pay cycle. "; ods text=" ";
	ods text= "Current Salary: &salary. "; ods text=" ";
	ods text= "Salary Increase: &increase. "; ods text=" ";
	ods text= "New Salary: &newsalary. "; ods text=" ";
	ods text= "Bonus: &bonus. "; ods text=" ";
run; quit;
ods pdf close;


options emailsys=smtp;
options emailport=25;
options emailauthprotocol=NONE;
options EMAILHOST="YOURMAILHOST";
filename outbox EMAIL;
data _null_;
	FILE outbox
	to=("&email.")
	from=("YOUREMAILADDRESS")
	sender=("YOUREMAILADDRESS")
	bcc=("&mgremail." "&deptmgremail.") 
	cc="YOUREMAILADDRESS"	   
	replyto="YOUREMAILADDRESS"
	importance="HIGH"
	sensitivity="COMPANY-CONFIDENTIAL"
    subject="&year. Annual Compensation Report: &name."
	attach=("C:\Users\YOURUSER\Desktop\SGF_Reports\&name._&department..pdf"); 
file outbox;
put "Dear &name.:"; put ;
put "Thank you for being a valuable part of our company's growth and success. Every year, we aim to reward our employees with merit increases and bonuses."; put ;
put "Your annual employee compensation report is attached. Please follow up with your manager if you have any questions."; put ;
put "Thank you,";
put "Company";
run;
%mend sendreports;

/* Run sendreports macro with employee contact table values as input variables. Include obs=1 below for testing to avoid generating many emails. */
data _null_;
  set employee.contact /*(obs=1)*/;
  by employee_number;  
  if first.employee_number then do; 
  call execute(cats('%sendreports(',department,',',email,',',name,',',mgremail,',',deptmgremail,',',salary,',',increase,',',newsalary,',',bonus,')'));
  end;
 run; 
