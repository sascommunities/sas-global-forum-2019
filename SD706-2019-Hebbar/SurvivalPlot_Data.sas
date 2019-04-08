libname data '.';
ods _all_ close;
ods listing;

/*--Get survival plot data from LIFETEST procedure--*/
ods graphics on;
ods output SurvivalPlot=data.SurvivalPlotData;
ods select SurvivalPlot;
proc lifetest data=sashelp.BMT plots=survival(atrisk=0 to 2500 by 500);
   time T * Status(0);
   strata Group / test=logrank adjust=sidak;
run;
