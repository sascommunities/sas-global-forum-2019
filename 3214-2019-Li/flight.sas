
proc format;
value wkday
1='Monday'
2='Tuesday'
3='Wednesday'
4='Thursday'
5='Friday'
6='Saturday'
7='Sunday'
;
run;

proc format;
value hours
0='Morning'
1='Noon'
2='Evening'
3='Night';
;
run;

data tmp;
set sasuser.flight;
aaa=floor(crs_dep_time/100);
if aaa >= 4 & aaa < 10 then hours=0;
else if aaa >= 10 & aaa < 16 then hours=1;
else if aaa >= 16 & aaa < 22 then hours=2;
else hours=3; 
format crs_dep_time hours.;
run;

proc sort data=tmp out=sorted;
by hours;
run;

proc template;
define statgraph pie;
begingraph / pad=0px border=false opaque=false designwidth=100px designheight=100px dataskin=pressed;
layout region;
piechart category=hours response=DEP_DELAY_NEW /datalabelcontent=none display=all outlineattrs=(color=white) stat=mean centerfirstslice=true;
endlayout;
endgraph;
end;
run;

ods _all_ close;
ods listing gpath="&gpath";

ods graphics / reset imagename='mon' ;
proc sgrender data=sorted(where=(day_of_week = 1 & dep_time ne .)) template=pie;
run;

ods graphics / reset imagename='tue' ;
proc sgrender data=sorted(where=(day_of_week = 2 & dep_time ne .)) template=pie;
run;

ods graphics / reset imagename='wed' ;
proc sgrender data=sorted(where=(day_of_week = 3 & dep_time ne .)) template=pie;
run;

ods graphics / reset imagename='thu' ;
proc sgrender data=sorted(where=(day_of_week = 4 & dep_time ne .)) template=pie;
run;

ods graphics / reset imagename='fri' ;
proc sgrender data=sorted(where=(day_of_week = 5 & dep_time ne .)) template=pie;
run;

ods graphics / reset imagename='sat' ;
proc sgrender data=sorted(where=(day_of_week = 6 & dep_time ne .)) template=pie;
run;

ods graphics / reset imagename='sun' ;
proc sgrender data=sorted(where=(day_of_week = 7 & dep_time ne .)) template=pie;
run;

proc summary data=sasuser.flight nway;
var dep_delay_new;
class day_of_week / ;
output out=myflight_mean mean=;
run;

proc template;
define statgraph pie_scatter;
begingraph / datasymbols=(mon tue wed thu fri sat sun);
entrytitle 'Average departure delay by day-of-week';
entrytitle 'Pie chart shows average departure delay for part-of-day';
entrytitle 'Size of the pie indicates the number of flights';
entryfootnote halign=left 'From ontime flight data in Q1 of 2012';
symbolimage name=mon image="&gpath/mon.png";
symbolimage name=tue image="&gpath/tue.png";
symbolimage name=wed image="&gpath/wed.png";
symbolimage name=thu image="&gpath/thu.png";
symbolimage name=fri image="&gpath/fri.png";
symbolimage name=sat image="&gpath/sat.png";
symbolimage name=sun image="&gpath/sun.png";
legenditem type=fill name='mo' / label='Morning: 4AM-10AM' fillattrs=graphdata1;
legenditem type=fill name='no' / label='Noon: 10AM-4PM' fillattrs=graphdata2;
legenditem type=fill name='ev' / label='Evening: 4PM-10PM' fillattrs=graphdata3;
legenditem type=fill name='ni' / label='Night: 10PM-4AM' fillattrs=graphdata4;

layout overlay / 
xaxisopts=(type=discrete discreteopts=(colorbands=odd) offsetmin=0.1 offsetmax=0.1) 
yaxisopts=(linearopts=(tickvalueformat=(extractscale=true)) offsetmin=0.15 offsetmax=0.15);
seriesplot x=day_of_week y=dep_delay_new / lineattrs=(color=black);
scatterplot x=day_of_week y=dep_delay_new / group=day_of_week markersizeresponse=_freq_ markersizemin=40px markersizemax=70px;
discretelegend 'mo' 'no' 'ev' 'ni' / across=1 location=inside halign=left valign=top border=false;
endlayout;
endgraph;
end;
run;

ods _all_ close;
ods listing gpath="&gpath" image_dpi=200;
ods graphics / reset scalemarkers=off width=600px imagename="flight_pie";

proc sgrender data=myflight_mean template=pie_scatter;
format day_of_week wkday.;
label dep_delay_new='Average departure delay';
label day_of_week='Day of week';
run;

