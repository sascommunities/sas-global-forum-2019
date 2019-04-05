%let gpath='C:\Work\Sugi\SGF2016\SuperDemos\Clinical_Graphs\Image';
%let dpi=300;
ods html close;
ods listing gpath=&gpath image_dpi=&dpi;

data Measles;
  input Year Cases Vaccine;
  datalines;
1998   100  92
1999   120  88
2000   100  88
2001   400  87
2002   500  84
2003   450  82
2004   250  80
2005   150  81
2006   700  85
2007  1000  87
2008  1300  85
2009  1100  86
2010   500  88
2011  1000  89
2012  2000  91
;
run;
/*proc print;run;*/

ods graphics / reset attrpriority=color width=5in height=3in imagename='Measels';
title 'Measles Cases and MMR Uptake by Year';
proc sgplot data=Measles noborder;
  vbar year / response=vaccine  nostatlabel y2axis fillattrs=(color=green) filltype=gradient
              baselineattrs=(thickness=0) baseline=0;
  vline year / response=cases nostatlabel  lineattrs=(color=red thickness=3);
  keylegend / location=inside position=top linelength=15;
  yaxis offsetmin=0 display=(noline noticks) thresholdmax=0 max=2500 grid 
        label='Measels Cases in England and Wales' labelattrs=(color=red);
  y2axis offsetmin=0 min=0 max=95 display=(noline noticks) thresholdmax=0 
        label='MMR Uptake for England' labelattrs=(color=green);
  xaxis display=(nolabel noticks) valueattrs=(size=7);
run;
title;
