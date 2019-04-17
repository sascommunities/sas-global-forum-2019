/* Traditional Way */
ods html body="s:\cdma\feldesmana\private\teleworkeval\analysis\tabulate _example1.html" (Title='Position Teleworker 2018 Survey')
headtext="<style> hr {page-break-after;always} thead {display;table-header-group}
 @media all {font {font-size=80%}} </style>" style=styles.test1;

%macro an1 (var=var, title=title);
proc tabulate data=fin missing; class &var/preloadfmt; 
where 1<=&var<=6 and finish=1 ;
class q17; 
tables all='Total'   q17='Position' ,
(&var=' '*(pctn<&var>='%'*f=6.1 n='Number of Cases'*f=comma8.) all*n='Total Cases'*f=6.0) /
rts=55 printmiss misstext='0';
title &title;  run; 
%mend an1;


%an1 (var=q1a,title= 'Q1a. Topic 1'); run;
%an1 (var= q1b,title= 'Q1b. Topic 2'); run;
%an1 (var= q1c,title= 'Q1c. Topic 3'); run;

/* Tip 1 */

proc contents noprint data=fin2 out=newone; run;

data newone2; set newone; keep name varnum label; if format ne ' '; run;

data newone3; length name $6.;  set newone2;
pt1="%an1 (var=";
pt2=pt1||left(trim(name));
pt3=pt2||', title="';
pt4=pt3||left(trim(label));
pt5=pt4||'");run;'; run; 

proc sort data=newone3; by varnum;
proc print data=newone3; var pt5; ;run;

filename out 'g:\teleworkereval\analysis\data.TXT';

DATA OUT; FILE OUT lrecl=32532; SET newone3;
PUT
pt5 '09'x;
run; 
 

OPTIONS SOURCE NOSTIMER NOCENTER PAGESIZE = 60 LINESIZE = 132 NOQUOTELENMAX;

/*Comment:  This template controls the appearance of the fonts and uses a minimal style sheet*/
proc template;
define style styles.test;
parent=styles.minimal;
style systemtitle from systemtitle /
   font_face=helvetica font_size=3
   font_weight=bold just=l;
style systemfooter from systemfooter /
  font_face=helvetica font_size=3;
style header from header/
  font_face=helvetica
   just=l vjust=b;
style data from data/
  font_face=helvetica;
style rowheader from rowheader/
 font_face=helvetica;
 style table from table /
    just=left; end; run; 

/*Comment:  This template controls the appearance of the fonts and uses a sasweb style sheet.  This is desirable as it shades every other row for readability*/
  
ods path work.templat(update) sashelp.tmplmst(read);
proc template;
  define style styles.test2;
    parent=styles.sasweb;
      class rowheader /
         protectspecialchars=off;
   end;
run;
/*Comment:  The libname shows where the data are stored.  The formats are the translation of the response options to words to represent the scale respondents were given.*/

LIBNAME qpldir 's:\cdma\feldesmana\private\teleworkeval\analysis';

PROC FORMAT;
     VALUE   _0001_   1 = 'Very positive impact'
                      2 = 'Generally positive impact'
                      3 = 'No impact'
                      4 = 'Generally negative impact'
                      5 = 'Very negative impact'
                      6 = 'Not applicable/No basis to judge'
                      7=  'No response';

     
                      
VALUE   _0010_   1='PDP, Band I or Band II Analyst, Analyst-Related (Specialist), Communications Analyst (Band I or II)'
2='Administrative Professional and Support Staff (APSS) (AC or PT)'
3='Band III Analyst, Analyst-Related (Specialist),  Supervisory Communications Analyst (Band III), Supervisory or non-Supervisory Attorney in PA payplan, or Managerial and Supervisory (MS)'
4='SES or Senior Level (SL); incl Attorneys in SES payplan'; run; 
                     

/*Comment:  This is the format that will be used to do the color coding*/

proc format; 
             value neg  5-high='red';
             value pos  75-high ='light green'; run;
/*Comment: I set one=1 because I want a generally place holder for any where clauses*/ 
data fin; set qpldir.fin; one=1;  run; 
/*Comment:  These are the placeholders.  When they are merged with the data set all response options will be filled either with a zero or a value.  If you do not perform this step the proc transpose will shift your data*/

data holderpos; input cols val  @@; cards;
1 0 2 0 3 0 
;
data holderpos2; input cols val  @@; cards;
1 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 
;
run;
/*Comment:  This is the macro that creates the collapsing of the scale into fewer response options*/

%macro ch (var=var,demo=demo,lab=lab, where=where);
data finy;   set fin;  demo=&demo; if finish=1;
if 1<=&var<=3 then new&var=1; else if 4<=&var<=5 then new&var=2; else new&var=3;

/*Comment:  This frequency produces an agency wide percentages.  The sparse option provides all possible combinations of levels of the variables in the table, even when some combination levels do not occur in the data.*/

proc freq data=finy noprint; tables new&var/out=gao&var sparse; where &where; data gao&var; set gao&var; drop count; run;
data gao&var; set gao&var;
if new&var=1 then cols=1;
if new&var=2 then cols=2;
if new&var=3 then cols=3;
run;

proc sort data=gao&var; by cols;proc sort data=holderpos; by cols;  RUN;

/*Comment:  This is where the place holder is merged with the data set so that all response options will occur in the data set*/

data gao&var; merge gao&var holderpos; by cols;
if percent=. then percent=0;
IF cols=1 and new&var=. then new&var=1; 
IF cols=2 and new&var=. then new&var=2; 
IF cols=3 and new&var=. then new&var=3;  
run;

/*Comment:  This transpose makes the percentages become columns rather than rows*/

proc transpose data=gao&var out=tgao&var; run;

/*Comment:  This data step keeps only the percentage information.  In order to keep track of which percentages are gao-wide versus by demographics, the variable is renamed perct*/
 
data tgao&var; set tgao&var; if _NAME_='PERCENT'; if _NAME_='PERCENT' then _NAME_='perct';  run;

/*Comment:  In order to keep track of which percentages are gao-wide versus by demographics, the columns 1 to 3 are renamed 13 to 15.  The selection of 13 to 15 is dependent on the number of levels of the demographic variable being analyzed.  In this case we are looking at a demographic variable with 4 levels with the collapsing of the response options into 3 levels.  Hence, the percentages for the demographic variable will take on 12 levels.  That is why the agency wide results are coded 13 to 15.*/
data tgao&var; set tgao&var;
col13=col1;
col14=col2;
col15=col3;

drop col1 col2 col3 _LABEL_; run;

proc sort data=finy;by &demo;  run;

/*Comment:  This is the end of the creation of the agency wide results.  The same approach is used for the demographic variable that has 4 levels.*/

/*Comment:  We begin again with the frequencies being retained in a data set using the sparse option.  You will need frequencies as the percentages will be calculated in a later data step*/
 
proc freq data=finy noprint; tables &demo*new&var/out=&var&demo sparse; where 1<=&demo<=4 and &where;  run;

/*Comment:  This takes the data set and creates 12 columns of the results.  One for each of the 3 recodes of the response options with each of the 4 levels of the demographic variable*/

DATA &var&demo; SET &var&demo;
if new&var=1 and &demo=1 then cols=1;
if new&var=2 and &demo=1 then cols=2;
if new&var=3 and &demo=1 then cols=3;

if new&var=1 and &demo=2 then cols=4;
if new&var=2 and &demo=2 then cols=5;
if new&var=3 and &demo=2 then cols=6;

if new&var=1 and &demo=3 then cols=7;
if new&var=2 and &demo=3 then cols=8;
if new&var=3 and &demo=3 then cols=9;

if new&var=1 and &demo=4 then cols=10;
if new&var=2 and &demo=4 then cols=11;
if new&var=3 and &demo=4 then cols=12;
RUN;

proc sort data=&var&demo; by cols;
proc sort data=holderpos2; by cols;  run;
/*Comment:  Here is where the place holder is used so that all combinations will either be 0 or some value.  This ensures that the proc transpose does not distort the data*/

data &var&demo; merge &var&demo holderpos2; by cols;
if PERCENT=. THEN PERCENT=0;
IF COLS=1 AND NEW&VAR=. and &demo=1 THEN NEW&VAR=1;
IF COLS=2 AND NEW&VAR=. and &demo=1 THEN NEW&VAR=2;
IF COLS=3 AND NEW&VAR=. and &demo=1 THEN NEW&VAR=3;
IF COLS=4 AND NEW&VAR=. and &demo=2 THEN NEW&VAR=4;
IF COLS=5 AND NEW&VAR=. and &demo=2 THEN NEW&VAR=5;
IF COLS=6 AND NEW&VAR=. and &demo=2 THEN NEW&VAR=6;
IF COLS=7 AND NEW&VAR=. and &demo=3 THEN NEW&VAR=7;
IF COLS=8 AND NEW&VAR=. and &demo=3 THEN NEW&VAR=8;
IF COLS=9 AND NEW&VAR=. and &demo=3 THEN NEW&VAR=9;
IF COLS=10 AND NEW&VAR=. and &demo=4 THEN NEW&VAR=10;
IF COLS=11 AND NEW&VAR=. and &demo=4 THEN NEW&VAR=11;
IF COLS=12 AND NEW&VAR=. and &demo=4 THEN NEW&VAR=12;
run; 

proc sort data=&var&demo; by &demo; run; 

/*Comment:  This is the place where the denominator is calculated so that the percentages for each of the demographic levels can be calculated*/

proc means data=&var&demo sum noprint; var count; by &demo; output out=s&var&demo sum=scount; run;

data s&var&demo; set s&var&demo; drop _TYPE_ _FREQ_; run;
proc sort data=s&var&demo; by &demo; run;
/*Comment:  This is where the percentages are calculated for each of the 12 columns*/

data m&var&demo;  merge &var&demo s&var&demo;by &demo; perct=(count/scount)*100;  
if perct=. then perct=0;
run;

proc sort data=m&var&demo; by cols; run;
/*Comment:  Here is where the transpose is conducted so that the data set will have columns rather than rows of the percentages.*/

proc transpose data=M&var&demo out=t&var&demo; run;
data t&var&demo; length lab $200.; set t&var&demo; if _NAME_='perct'; lab=&lab;  run;
/*Comment:  Finally the agency wide and the demographic percentages are combined.*/

data &var&demo; merge tgao&var t&var&demo; run;
%mend ch;
/*Comment:  Here is where each of the survey questions are run through the macro along with the specific demographic variable.  To maintain the integrity of the data I needed to specify simply Topics 1 to 12.  In the actual analysis the title of the specific questions are used.*/


%ch (where=one=1,var=Q1A, demo=q19, lab='Q1a. Topic 1');run;
%ch (where=one=1,var=Q1B, demo=q19,lab  = 'Q1b. Topic 2'); run;
%ch (where=one=1,var=Q1C, demo=q19,lab  = 'Q1c. Topic 3'); run;
%ch (where=one=1,var=Q1D, demo=q19,lab  = 'Q1d. Topic 4'); run;
%ch (where=one=1,var=Q1E, demo=q19,lab  = 'Q1e. Topic 5'); run;
%ch (where=one=1,var=Q1F, demo=q19,lab  = 'Q1f. Topic 6'); run;
%ch (where=one=1,var=Q1G, demo=q19,lab  = 'Q1g. Topic 7'); run;
%ch (where=one=1,var=Q1H, demo=q19,lab  = 'Q1h. Topic 8'); run;
%ch (where=one=1,var=Q1I, demo=q19,lab  = 'Q1i. Topic 9'); run;
%ch (where=one=1,var=Q1J, demo=q19,lab  = 'Q1j. Topic 10'); run;
%ch (where=one=1,var=Q1K, demo=q19,lab  = 'Q1k. Topic 11'); run;
%ch (where=one=1,var=Q1L, demo=q19,lab  = 'Q1l. Topic 12'); run;

/*Comment:  Here is where all of the survey questions are stacked on top of each other so that the rows are the survey questions and the columns are the percentages.*/
data all;  set q1aq19 q1bq19 q1cq19 q1dq19 q1eq19 q1fq19 q1gq19 q1hq19 q1iq19 q1jq19 q1kq19 q1lq19; run; 


ods listing close;
/*Comment:  This is a code to write out a file that I called Position_example_2018.html*/

ods html body="s:\cdma\feldesmana\teleworkeval\analysis\Position_example_2018.html" 
(Title='Position Teleworker 2018 Survey') headtext="<style> hr {page-break-after:always} thead
{display:table-header-group}  @media all {font {font-size=80%}} </style>" style=styles.test;

/*Comment:  This is a basic proc report to create a table*/

proc report data=all nowindows spacing=1 pspace=1 split='*' missing headline;

column lab col13 col14 col15 col1 col2 col4 col5 col7 col8 col10 col11;
/*Comment:  Here you will the use of the style column background where I use the pos. format for positive color coding and neg. format for the negative color coding*/

define lab /display ' ' format=$220. style ={just=left cellwidth=2in};
define col13/display 'GAO-wide*pos*1' format=4.1 style(column)={background=pos.};
define col14/display 'GAO-wide*neg*2' format=4.1 style(column)={background=neg.};
define col15/display 'GAO-wide*unk*3' format=4.1 style(column)={background=oth.};
define col1/display 'Staff*pos*1' format=4.1 style(column)={background=pos.};
define col2/display 'Staff*neg*2' format=4.1 style(column)={background=neg.};
define col4/display 'Support*pos*1' format=4.1 style(column)={background=pos.};
define col5/display 'Support*neg*2' format=4.1 style(column)={background=neg.};
define col7/display 'Manager*pos*1' format=4.1 style(column)={background=pos.};
define col8/display 'Manager*neg*2' format=4.1 style(column)={background=neg.};
define col10/display 'SES*pos*1' format=4.1 style(column)={background=pos.};
define col11/display 'SES*neg*2' format=4.1 style(column)={background=neg.};
title1 'All respondents-by position'; run;

/*Comment:  Here is the more tradition code that uses tabulate to create a table for a total and each of the demographic variables. To maintain the integrity of the data I needed to specify simply Topics 1 to 12.  In the actual analysis the title of the specific questions are used.*/

%macro an1 (var=var, title=title);
proc tabulate data=fin missing; class &var/preloadfmt; where 1<=&var<=7 and finish=1; class q19;
tables all='Total' q19='Position',
(&var=' '*(pctn<&var>='%'*f=6.1 n='Number of Cases'*f=comma8.) all*n='Total Cases'*f=6.0) /rts=55 printmiss misstext='0';title &title;  RUN;
%mend an1;

%an1 (var=Q1A, title  = 'Q1a. Topic 1'); run;
%an1 (var=Q1B, title  = 'Q1b. Topic 2'); run;
%an1 (var=Q1C, title  = 'Q1c. Topic 3'); run;
%an1 (var=Q1D, title  = 'Q1d. Topic 4'); run;
%an1 (var=Q1E, title  = 'Q1e. Topic 5'); run;
%an1 (var=Q1F, title  = 'Q1f. Topic 6'); run;
%an1 (var=Q1G, title  = 'Q1g. Topic 7'); run;
%an1 (var=Q1H, title  = 'Q1h. Topic 8'); run;
%an1 (var=Q1I, title  = 'Q1i. Topic 9'); run;
%an1 (var=Q1J, title  = 'Q1j. Topic 10'); run;
%an1 (var=Q1K, title  = 'Q1k. Topic 11'); run;
%an1 (var=Q1L, title  = 'Q1l. Topic 12'); run;

ods html close; run;

