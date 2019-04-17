/*This is for the Life Tables for the Texas Vital Statistics Annual Report Table 24*/

/*started by A. Vincent 11/15/2016*/
/*some information from a very old SAS paper named "SAS Macros for Generating Abridged and Cause-Eliminated Life Tables"*/
/*by Zhao Yang, Xuezheng Sun. */
/******************************************************************************************************/

/*put in the year that is needed for the final output*/
%let year=2014;
/*the #byval() prints the values of the column in the by group section of the report*/
%let title1="Abridged Life Tables*** for AR Table 24 by #byval(sexRace) for &year";
/*footnotes can be added or not depending on how you use the output report*/
%let footnote1="*Life expectancy at birth.";
%let footnote2="**Includes other and unknown race/ethnicity.";
%let footnote3="Life tables prepared using SAS.";
%let footnote4="See Technical Appendix for Life Table Construction.";

/*this can imputted in the order below. There should only be one space between columns*/
/*of course one can change the space to any delimiter.*/
data tests;
   length sexRace $2. years agegroup population deaths births ax 8.;
   input sexRace $ years agegroup population deaths births ax ;
   datalines;
at 1 0 401044 2320 399482 0.15
at 4 1 1563818 373 399482 1.65
at 5 5 1963917 262 399482 2.25
at 5 10 2027727 302 399482 3.05
at 5 15 1989542 906 399482 2.75
at 5 20 1973591 1654 399482 2.55
at 5 25 1910287 1874 399482 2.50
at 5 30 1951334 2125 399482 2.55
at 5 35 1813357 2487 399482 2.65
at 5 40 1825703 3569 399482 2.70
at 5 45 1709853 5356 399482 2.70
at 5 50 1764935 8818 399482 2.65
at 5 55 1630397 12291 399482 2.65
at 5 60 1349362 14806 399482 2.65
at 5 65 1083217 16343 399482 2.60
at 5 70 760459 17956 399482 2.60
at 25 75 1238416 91855 399482 11.50
ft 1 0 194646 1007 194979 0.15
ft 4 1 764955 168 194979 1.65
ft 5 5 960900 115 194979 2.25
ft 5 10 989236 114 194979 3.05
ft 5 15 965360 266 194979 2.75
ft 5 20 948945 415 194979 2.55
ft 5 25 925680 548 194979 2.50
ft 5 30 970116 677 194979 2.55
ft 5 35 911476 944 194979 2.65
ft 5 40 925158 1400 194979 2.70
ft 5 45 859900 2082 194979 2.70
ft 5 50 893108 3444 194979 2.65
ft 5 55 833271 4749 194979 2.65
ft 5 60 702069 5880 194979 2.65
ft 5 65 568654 6846 194979 2.60
ft 5 70 408181 7837 194979 2.60
ft 25 75 732930 51773 194979 12.40
mt 1 0 202827 1313 204503 0.15
mt 4 1 798863 205 204503 1.65
mt 5 5 1003017 147 204503 2.25
mt 5 10 1038491 188 204503 3.05
mt 5 15 1024182 640 204503 2.75
mt 5 20 1024646 1239 204503 2.55
mt 5 25 984607 1326 204503 2.50
mt 5 30 981218 1448 204503 2.55
mt 5 35 901881 1543 204503 2.65
mt 5 40 900545 2169 204503 2.70
mt 5 45 849953 3274 204503 2.70
mt 5 50 871827 5374 204503 2.65
mt 5 55 797126 7542 204503 2.65
mt 5 60 647293 8926 204503 2.65
mt 5 65 514563 9497 204503 2.60
mt 5 70 352278 10119 204503 2.60
mt 25 75 505486 40082 204503 10.30
;
run;

/**********FORMATS********************************************/

proc format;
value $agef '0'='< 1' '1'='1-4' '5'='5-9'  '10'='10-14'  '15'='15-19'  '20'='20-24'  '25'='25-29'  '30'='30-34'  
				'35'='35=39'  '40'='40-44'  '45'='45-49' '50'='50-54'  '55'='55-59' '60'='60-64'  '65'='65-69'  
				'70'='70-74' '75'='75+';
value $sexf 'at'='All Texas'
			'bt'='All Blacks'
			'ht'='All Hispanics'
			'wt'='All Whites**'
			'ft'='All Females'
			'mt'='All Males'
			'bf'='Black Females'
			'bm'='Black Males'
			'hf'='Hispanic Females'
			'hm'='Hispanic Males'
			'wf'='White Females**'
			'wm'='White Males**'
;
run;

/*******************************************************/
/*here we are creating the qx of our table. We must be sure that it loops around the years column*/
/*if you change the years to include some groups over the age of 75, increase the do loop*/

* 2. Check to see if all the tables are here;
Proc Freq Data=tests;
   Tables sexRace/Nocol Norow Nopercent Nocum;
Title 'check to see if there are 12 sexRace groups';
Run;

*3. Calculate qx dr p [qx=Proportion dying 
                       dr=death rate 
                        p=1-qx];
Data test1;	
   Set tests;
   Length qx dr p 8;
   If Years=1 then Do;
     dr=deaths/births;
	 qx=deaths/births;
   End;
   Else Do;
     dr=deaths/population;
     If agegroup=1 then qx=2*4*dr/(2+4*dr);
	 Else If agegroup=75 then qx=1.000000;
     Else qx=2*5*dr/(2+5*dr);
     End;
   p=1-qx;
   Format qx dr p 8.5;
Run;

Proc Print Data= test1;
Title 'Test1: calculating qx dr p';
Run;

*4. Calculate Ix= number of people living at the begining of each age interval;
Data test2;
   Set test1;
   Length x xx Ix 8;
   If years=1 then Do;
        x=1;
		x=x*p;
		xx=1;
		Ix=100000;
   End;
   Else do;
   		Retain x;
        xx=x;
		Ix=100000*xx;
	    x=x*p;	

   End;
Format Ix comma8.0;
run;

Proc Print Data=test2;
Title 'Test2: Calculating lx';
Run;

*5. Calculate dx Lx [dx=Expected number of death in each agegroup
                     Lx=Number of Person Year Lived];
Proc Sort Data=test2;
   by sexRace descending Agegroup;
Run;

Data test3;
   Set test2;
   Length LagIx dx Lx 8;
   LagIx=lag(Ix);
   if Agegroup=75 then LagIx=0;
   dx = Ix -LagIx; 
   Lx=years*lagIx + dx*ax;
   Format LagIx dx Lx comma8.0;
Run;

Proc Print data=test3;
title ' Test3: Calculate dx and Lx ';
Run;

*6. Calculate Tx Ex [Tx=Person years lived in each age interval and all subsequent age intervals
                     Ex=Expectation of life ];
Data Final; 
   Do j= 1 to 12;
   Tx = 0;
      Do i = 1 to 17;
      Set Test3; 
      Tx + Lx;
	  Ex=Tx/Ix;
      output;
	  End;
   End;
Drop Tx j i;
Format Tx 8.0 Ex 8.2;
Run;

/*************************************************************/
/*final sort*/
proc sort data=Final;
by sexRace;
run;

/*this creates a template for the output file. You don't have to use, but it looks nice*/
proc template;
	define style self.border;
		parent=styles.SansPrinter;
			style Table /
				rules = groups
				frame=hsides
				cellpadding = 3pt
				cellspacing = 0pt
				borderwidth = 2pt;
			style header /
				font_weight=bold
				background=white
				font_size=3;
		end;
run;

/*options nobyline stops SAS from printing the "by" section of the report */
options nodate noBYLINE;

/*we can print this out to any output that SAS has or just run the proc report section*/

ods listing close;
/* put the output where you want it.*/
ods pdf file="c:\temp\test24.pdf" style=self.border;

Proc report data=final headline headskip nowd spacing=2 split='-' center ;
by sexRace ; 
format sexRace $sexf. ;

columns agegroup years deaths population qx Ix dx ax Lx ex ;

define agegroup /display f=agef. "Age-Group" width=5 center;
define years /display "-Years" width=5 center;
define deaths /display f=comma12.0 "Number-of Deaths" width=9 center;
define population /display f=comma12.0 "Estimated-Population" width=10 center;
define qx /display f=12.5 "-(qx)" width=11 center;
define Ix /display f=comma12.0 "-(Ix)" width=11 center;
define dx /display f=comma12.0 "-(dx)" width=14 center;
define ax / display f=8.2 "-(ax)" width=6 center;
define Lx /display f=comma12.0 "-(Lx)" width=14 center;
define ex /display f=12.2 "-(ex)" width=18 center;

title &title1;
footnote1 &footnote1;
footnote2 &footnote2;
footnote3 &footnote3;
footnote4 &footnote4;

run;

ods pdf close;
ods listing;

/*clear the titles and footnotes*/
title ;
footnote1 ;
footnote2 ;
footnote3 ;
footnote4 ;

/*end of syntax*/

