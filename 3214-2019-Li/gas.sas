%let product=gas;

proc summary data=sashelp.gulfoil nway;
var &product;
class date / ;
output out=mygas_all sum=;
run;

data mygas;
set mygas_all;
mon=month(date);
monname=put(date, monname3.);
run;

proc sql noprint;
select min(&product), max(&product) into :min, :max
from mygas;
select distinct monname, mon into 
       :symbols separated by ' ', :values separated by ' '   
from mygas order by mon;
quit;

proc summary data=mygas nway;
var &product;
class mon;
output out=mygas_mean mean=;
run;

proc sql noprint;
select mon into :monmax
from mygas_mean having &product=max(&product);
quit;

%subseries_template(x=date, y=&product, ymin=&min, ymax=&max, size=100px);
%all_subseries_plots(symbols=&symbols, data=mygas, wherevar=mon, wherevalues=&values, maxvalue=&monmax);

%let ticks=%sysfunc(catq('1a',%sysfunc(translate(%upcase(&symbols),%str(,),%str( )))));
%cycle_plot_template(x=mon, y=&product, symbols=&symbols, ticks=&ticks);

ods _all_ close;
ods listing gpath="&gpath" image_dpi=200;
ods graphics / reset scalemarkers=off height=600px imagename="gas_cycle_plot";

proc sgrender data=mygas_mean template=cycle_plot_graph;
label mon='Month';
dynamic title1="Average monthly &product production, Gulf of Mexico 1996-2006" 
        title2="Subseries shows a spline fit of &product production over the years for each month" 
        footnote='Data from sashelp.gulfoil';
run;

