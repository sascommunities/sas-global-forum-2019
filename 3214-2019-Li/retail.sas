
data myretail;
set sashelp.retail;
length qtrname $2;
qtr=qtr(date);
qtrname=cat("Q", qtr);
run;

proc sql noprint;
select min(sales), max(sales) into :sales_min, :sales_max
from myretail;
select distinct qtrname, qtr into 
       :symbols separated by ' ', :values separated by ' '   
from myretail order by qtr;
quit;

proc summary data=myretail nway;
var sales;
class qtr;
output out=myretail_mean mean=;
run;

proc sql noprint;
select qtr into :qtrmax
from myretail_mean having sales=max(sales);
quit;

%subseries_template(x=year, y=sales, ymin=&sales_min, ymax=&sales_max, size=150px);
%all_subseries_plots(symbols=&symbols, data=myretail, wherevar=qtr, wherevalues=&values, maxvalue=&qtrmax);

%let ticks=%sysfunc(catq('1a',%sysfunc(translate(%upcase(&symbols),%str(,),%str( )))));
%cycle_plot_template(x=qtr, y=sales, symbols=&symbols, ticks=&ticks);

ods _all_ close;
ods listing gpath="&gpath" image_dpi=200;
ods graphics / reset scalemarkers=off width=600px imagename="retail_cycle_plot";

proc sgrender data=myretail_mean template=cycle_plot_graph;
label qtr='Quarter';
dynamic title1='Quarterly retail sales' 
        title2='Subseries shows sales over the years 1980 to 1994' 
        footnote='Data from sashelp.retail';
run;


