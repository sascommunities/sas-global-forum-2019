libname data '.';
%let gpath=".";
%let dpi=300;

/**
 * The graph data set is created from LIFETEST procedure on sashelp.BMT
 * by grabbing ods output SurivalPlotData.
 * %include 'SurvivalPlot_Data.sas';
 */


/* Survival Plot with outer Risk Table using AxisTable and legendItem */
ods listing style=htmlblue image_dpi=&dpi gpath=&gpath; 
ods graphics / reset width=5in height=3in imagename='Survival Plot';

title 'Product-Limit Survival Estimates';
title2  h=0.8 'With Number of Subjects at Risk';
footnote j=l h=6pt italic 'This visual is for discussion of graph features only.'  
         '  The actual details should be customized by user to suit their application.';
proc sgplot data=data.SurvivalPlotData;
  step x=time y=survival / group=stratum name='step';
  scatter x=time y=censored / markerattrs=(symbol=plus) group=stratum;
  xaxistable atrisk / x=tatrisk class=stratum colorgroup=stratum valueattrs=(weight=bold);

  keylegend 'step' / linelength=20;

  legendItem name='censored' type=marker / label="Censored" markerattrs=(symbol=plus);
  keylegend 'censored' / location=inside position=topright;
run;

/*--Survival Plot with outer Risk Table using AxisTable with Ref line for Y axis--*/
ods listing style=htmlblue; 
ods graphics / reset width=5in height=3in imagename='Survival Plot_Ref';
title 'Product-Limit Survival Estimates';
title2  h=0.8 'With Number of Subjects at Risk';
footnote j=l h=6pt italic 'This visual is for discussion of graph features only.'  
         '  The actual details should be customized by user to suit their application.';
proc sgplot data=data.SurvivalPlotData noborder;
  styleattrs axisextent=data;
  dropline x=0 y=0.2 / dropto=y;
  dropline x=0 y=0.4 / dropto=y;
  dropline x=0 y=0.6 / dropto=y;
  dropline x=0 y=0.8 / dropto=y;
  dropline x=0 y=1.0 / dropto=y;
/*  refline 0 / axis=x;*/
  step x=time y=survival / group=stratum name='s';
  scatter x=time y=censored / markerattrs=(symbol=plus) name='c';
  scatter x=time y=censored / markerattrs=(symbol=plus) GROUP=stratum;
  xaxistable atrisk / x=tatrisk class=stratum colorgroup=stratum valueattrs=(weight=bold);
  keylegend 'c' / location=inside position=topright;
  keylegend 's' / linelength=20;
  yaxis display=(noline noticks);
run;


/*--Survival Plot with inner Risk Table using AxisTable--*/
ods listing style=htmlBlue;
ods graphics / reset width=5in height=3in imagename='Survival Plot_Inside';
title 'Product-Limit Survival Estimates';
title2  h=0.8 'With Number of Subjects at Risk';
footnote j=l h=6pt italic 'This visual is for discussion of graph features only.'  
         '  The actual details should be customized by user to suit their application.';
proc sgplot data=data.SurvivalPlotData;
  step x=time y=survival / group=stratum lineattrs=(pattern=solid) name='s';
  scatter x=time y=censored / markerattrs=(symbol=plus) name='c';
  scatter x=time y=censored / markerattrs=(symbol=plus) GROUP=stratum;
  xaxistable atrisk / x=tatrisk location=inside class=stratum colorgroup=stratum 
             separator valueattrs=(size=7 weight=bold) labelattrs=(size=8);
  keylegend 'c' / location=inside position=topright;
  keylegend 's' / linelength=20;
run;


/*--Survival Plot with inner Risk Table using AxisTable--*/
ods graphics / reset width=5in height=3in imagename='Survival Plot_Ref_Inside';
title 'Product-Limit Survival Estimates';
title2  h=0.8 'With Number of Subjects at Risk';
*footnote j=l h=6pt italic 'This visual is for discussion of graph features only.'  
         '  The actual details should be customized by user to suit their application.';
proc sgplot data=data.SurvivalPlotData noborder;
  styleattrs axisextent=data;
  dropline x=0 y=0.2 / dropto=y;
  dropline x=0 y=0.4 / dropto=y;
  dropline x=0 y=0.6 / dropto=y;
  dropline x=0 y=0.8 / dropto=y;
  dropline x=0 y=1.0 / dropto=both;
  step x=time y=survival / group=stratum lineattrs=(pattern=solid) name='s';
  scatter x=time y=censored / markerattrs=(symbol=plus) name='c';
  scatter x=time y=censored / markerattrs=(symbol=plus) GROUP=stratum;
  xaxistable atrisk / x=tatrisk location=inside class=stratum colorgroup=stratum 
              valueattrs=(size=7 weight=bold) labelattrs=(size=8);
  keylegend 'c' / location=inside position=topright;
  keylegend 's' / linelength=20;
  yaxis display=(noline noticks);
run;


/*--Survival Plot with padding for annotation--*/
ods graphics / reset width=5in height=3in imagename='Survival_Plot_Pad';
title 'Product-Limit Survival Estimates';
title2  h=0.8 'With Number of Subjects at Risk';
*footnote j=l h=6pt italic 'This visual is for discussion of graph features only.'
         '  The actual details should be customized by user to suit their application.';
proc sgplot data=data.SurvivalPlotData pad=(bottom=20pct);
  step x=time y=survival / group=stratum name='s';
  scatter x=time y=censored / markerattrs=(symbol=plus) name='c';
  scatter x=time y=censored / markerattrs=(symbol=plus) GROUP=stratum;
  keylegend 'c' / location=inside position=topright;
  keylegend 's' / linelength=20;
run;


title;
footnote;
