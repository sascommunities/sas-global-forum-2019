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
run;

/* Create model table for compensation table in report */
data comp_table;
retain Employee_Information Value;
input Employee_Information $ 1-30 Value $31-60;
datalines;
Department           
Prior Salary         
Increase             
New Salary           
Bonus                
;
run;

/* Create model table for merit table in report */
data merit;
retain Metric Milestone;
input Metric $ 1-30 Milestone $31-60;
datalines;
Performance Rating      
Years with Company      
Training Hours Completed
;
run;

/* Define macro to send employee compensation reports with additional options and elaborate report creation */
%macro sendreports(department,email,name,mgremail,deptmgremail,salary,increase,newsalary,bonus,performancerating,yearsatcompany,trainingtimeslastyear);

/* Denote ^ as escape character, set options to hide date and page number from report. Set report to portrait. Set option to suppress reports from opening */
ods _all_ close;
options nodate nonumber orientation=portrait;
ods escapechar="^";
ods noresults;

/* Populate model table for compensation with employee data */
data comp_table;
set comp_table;
if Employee_Information="Department" then Value="&department.";
if Employee_Information="Prior Salary" then Value="$&salary.";
if Employee_Information="Increase" then Value="$&increase.";
if Employee_Information="New Salary" then Value="$&newsalary.";
if Employee_Information="Bonus" then Value="$&bonus.";
run;

/* Populate model table for merit with employee data */
data merit;
set merit;
if Metric="Performance Rating" then Milestone="&performancerating.";
if Metric="Years with Company" then Milestone="&yearsatcompany. Years";
if Metric="Training Hours Completed" then Milestone="&trainingtimeslastyear. Hours";
run;

/* Denote output PDF file, and set titles for report. Title 1 is a logo image. All titles are left aligned */
ods pdf file="C:\Users\YOURUSER\Desktop\SGF_Reports\&name._&department..pdf";
title j=left bold "^S={preimage='C:\Users\YOURUSER\Desktop\Logo.png'}";
title2 j=left bold "&year. Employee Compensation Statement^n";
title3 j=left italic "Personal and Confidential ^n^n";

/* Include compensation table in report with style color and size settings. Label Variables as desired */
proc report data=comp_table split='00'x style(header)={background=CX3883A8 foreground=white font_size=7pt} style(column)=[font_size=7pt];
define Employee_Information / style(header)={cellwidth=3.5in}; define Value / style(header)={cellwidth=3.5in};
label Employee_Information="Metric";
label Value="Compensation";

/* Add text to precede compensation table */
ods text= "&name.,^n^n";
ods text= "Company recognizes excellent performance and rewards employees for helping the company achieve its business goals. When we succeed together, we share the rewards. Thank you for continuing to help Company solve our customers’ toughest business problems.^n^n";
ods text= "Congratulations, I am pleased to provide you with the following pay increase effective the next pay cycle. You have also been awarded a bonus, paid to you on the next pay cycle.^n^n";
ods text= "Company will provide eligible employees with an annual 401(k) contribution of 3% to be funded in April. Eligible employees also receive an additional 401(k) contribution of 3% of their eligible compensation each pay period, regardless if the employee chooses to contribute or not, bringing this year’s 401(k) contribution to 6%. 
This combined total outranks our competitors in 401(k) employer contributions. Helping you save for retirement is one of the ways Company invests in its employees.^n^n";

ods text="^n^S={font_weight=bold}Table 1. Compensation Summary ^S={}";

/* Include merit table in report with style color and size settings. Set startpage so that table is not pushed to new page. */
ods startpage=no;
proc report data=merit split='00'x style(header)={background=CX3883A8 foreground=white font_size=7pt} style(column)=[font_size=7pt];
define Metric / style(header)={cellwidth=3.5in}; define Milestone / style(header)={cellwidth=3.5in};

/* Add text to precede merit table */
ods text= "^nSalary increases and bonses are awarded based on merit. Please see below some of your milestones and contributions for the year that helped Company succeed.
 Please reach out to your manager if you are interested in training opportunities or have questions regarding your milestones.^n^n";

ods text="^n^S={font_weight=bold}Table 2. Milestone Summary ^S={}";

run; quit;
ods pdf close;

/* Generate email with above report attached. */
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
  call execute(cats('%sendreports(',department,',',email,',',name,',',mgremail,',',deptmgremail,',',salary,',',increase,',',newsalary,',',bonus,',',performancerating,',',yearsatcompany,',',trainingtimeslastyear,')'));
  end;
 run; 
