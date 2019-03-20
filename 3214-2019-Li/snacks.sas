
/* summarizing by date */
proc summary data=sashelp.snacks (where=(date >= '01jan2002'd && date < '31mar2002'd)) nway;
var qtysold;
class date;
output out=snacks_all sum=;
run;

/* timesies in Figure 1 */
proc template;
define statgraph timeseries;
begingraph;
layout overlay / xaxisopts=(griddisplay=on timeopts=(minorticks=true interval=week)) yaxisopts=(linearopts=(tickvalueformat=(extractscale=true)));
seriesplot x=date y=qtysold / splinetype=QUADRATICBEZIER splinepoints=10 markerattrs=(symbol=circlefilled) lineattrs=(color=black);
endlayout;
endgraph;
end;
run;

ods _all_ close;
ods listing gpath="&gpath";
ods graphics / imagename="snacks_time_series";
proc sgrender data=snacks_all template=timeseries;
run;

/* add DAY and DAYNAME columns */
data mysnacks;
set snacks_all;
day=weekday(date);
dayname=put(date, downame.);
run;

/* computing min/max */
proc sql noprint;
select min(qtysold), max(qtysold) into :qtysold_min, :qtysold_max from mysnacks;
select distinct dayname, day into
:symbols separated by ' ', :values separated by ' '
from mysnacks order by day;
quit;

/* computing mean on dow */
proc summary data=mysnacks nway;
var qtysold;
class day;
output out=mysnacks_mean mean=;
run;

/* finding daymax */
proc sql noprint;
select day into :daymax
from mysnacks_mean having qtysold=max(qtysold);
quit;

/* generating the subseries images */
%subseries_template(x=date, y=qtysold, ymin=&qtysold_min, ymax=&qtysold_max, size=200px); 
%all_subseries_plots(symbols=&symbols, data=mysnacks, wherevar=day,
wherevalues=&values, maxvalue=&daymax);

%let ticks=%sysfunc(catq('1a',%sysfunc(translate(%upcase(&symbols),
%str(,),%str( )))));
%cycle_plot_template(x=day, y=qtysold, symbols=&symbols, ticks=&ticks);

ods listing gpath="&gpath" image_dpi=200;
ods graphics / reset scalemarkers=off width=800px imagename="snacks_cycle_plot";
proc sgrender data=mysnacks_mean template=cycle_plot_graph;
label day='Day of week';
dynamic title1="Daily average snacks sold"
title2="Subseries shows the spline fit of snacks sold over time";
run;
