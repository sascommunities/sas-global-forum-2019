/*----------------------------------*/
/*      SAS Global Forum  2019      */
/*       Bayesian Time Series       */
/*                                  */
/*          Dr Aric LaBarr          */
/*----------------------------------*/

/* Load Needed Data */
proc import datafile = 'uschange.csv'
	out = us_econ dbms = csv replace;
run;

/* Reset the Format to Match Actual Data */
data us_econ;
  set us_econ;
  format Index yyq.;
run; 

/* Plot US Consumption Data */
proc sgplot data=us_econ;
  title 'US Personal Consumption Expenditure';
  series x = Index y = consumption;
  yaxis label='PCE Percent Changes';
  xaxis label='Date (Quarterly)';
run;

/* Set Training Data */
data train;
  set us_econ;
  if Index > '31DEC2014'd then Consumption = .;
run;

/* Exponential Smoothing Model */
proc esm data=train print=all plot=all lead=7 outfor=for_esm;
  forecast consumption / model=simple;
run;

data forecasts;
  set us_econ(rename=(Consumption=Full_Consumption));
  set for_esm(rename=(predict=for_esm));
  keep Index Full_Consumption for_esm;
run;

data esm_chart;
  set us_econ(rename=(Consumption=Full_Consumption));
  set for_esm;
run;

proc sgplot data=esm_chart noautolegend;
  title 'ESM Forecast - 1970Q1-2016Q3';
  series x = Index y = ACTUAL / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = PREDICT / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "ESM Forecast";
  band x = Index upper=UPPER lower=LOWER / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes';
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;

proc sgplot data=esm_chart(where=('01JAN2013'd <= Index)) noautolegend;
  title 'ESM Forecast - 2013Q1-2016Q3';
  series x = Index y = ACTUAL / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = PREDICT / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "ESM Forecast";
  band x = Index upper=UPPER lower=LOWER / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes' values=(-1.5 to 2.5 by 0.5);
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;

/* ARIMA Model - Testing for Unit Root & Model Selection */
proc arima data=train plot=all;
  identify var=consumption nlag=10 stationarity=(adf=2);
  identify var=consumption nlag=10 minic scan esacf P=(0:4) Q=(0:4);
run;
quit;

/* Building ARIMA Model */
proc arima data=train plot=all;
  identify var=consumption nlag=10;
  estimate p=3 method=ML;
  forecast lead=7 out=for_arima;
run;
quit;

data forecasts;
  set forecasts;
  set for_arima(rename=(forecast=for_arima));
  keep Index Full_Consumption for_esm for_arima;
run;

data arima_chart;
  set us_econ(rename=(Consumption=Full_Consumption));
  set for_arima;
run;

proc sgplot data=arima_chart noautolegend;
  title 'ARIMA Forecast - US Personal Consumption Expenditure';
  series x = Index y = Consumption / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = Forecast / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "ARIMA Forecast";
  band x = Index upper=U95 lower=L95 / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes';
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;

proc sgplot data=arima_chart(where=('01JAN2013'd <= Index)) noautolegend;
  title 'ARIMA Forecast - 2013Q1-2016Q3';
  series x = Index y = Consumption / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = Forecast / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "ARIMA Forecast";
  band x = Index upper=U95 lower=L95 / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes' values=(-1.5 to 2.5 by 0.5);
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;

/* Bayesian Autoregressive Model */
proc univariate data = train normal plot;
  var consumption;
  histogram consumption / kernel normal;
run;
quit;

proc mcmc data=train nmc=100000 seed=100 nthreads=8 propcov=quanew;
  parms alpha_1 alpha_2 alpha_3;
  parms sigma2 1;
  parms Y_0 Y_1 Y_2;

  prior alpha_: ~ normal(0,var = 1);
  prior sigma2 ~ igamma(shape = 3/10, scale = 10/3);
  prior Y_: ~ normal(0, var = 1 );

  mu = alpha_1*consumption.l1 + alpha_2*consumption.l2 + alpha_3*consumption.l3;
  model consumption ~ normal(mu, var = sigma2) icond=(Y_2 Y_1 Y_0);

  preddist outpred=predicted statistics=brief;

  ods output PredSumInt=for_bar;
run;

data forecasts;
  set forecasts;
  set for_bar(rename=(mean=for_bar));
  keep Index Full_Consumption for_esm for_arima for_bar;
run;

data bar_chart;
  set us_econ(rename=(Consumption=Full_Consumption));
  set train;
  set for_bar;
run;

proc sgplot data=bar_chart noautolegend;
  title 'Bayesian AR Forecast - US Personal Consumption Expenditure';
  series x = Index y = Consumption / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = Mean / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "Bayesian AR Forecast";
  band x = Index upper=hpdupper lower=hpdlower / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes';
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;

proc sgplot data=bar_chart(where=('01JAN2013'd <= Index)) noautolegend;
  title 'Bayesian AR Forecast - 2013Q1-2016Q3';
  series x = Index y = Consumption / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = Mean / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "Bayesian AR Forecast";
  band x = Index upper=hpdupper lower=hpdlower / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes' values=(-1.5 to 2.5 by 0.5);
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;

/* Vector Autoregressive Model */
proc varmax data=us_econ(where=('01JAN1970'd <= Index <= '31DEC2014'd)) plot=all;
  id index interval=quarter;
  model consumption income / p=3 lagmax=5
        print=(estimates diagnose);
  output out=for_var lead=7;
run;

data forecasts;
  set forecasts;
  set for_var(rename=(for1=for_var));
  keep Index Full_Consumption for_esm for_arima for_bar for_var;
run;

data var_chart;
  set us_econ(rename=(Consumption=Full_Consumption));
  set for_var;
run;

proc sgplot data=var_chart noautolegend;
  title 'VAR Forecast - US Personal Consumption Expenditure';
  series x = Index y = Consumption / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = For1 / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "VAR Forecast";
  band x = Index upper=UCI1 lower=LCI1 / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes';
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;

proc sgplot data=var_chart(where=('01JAN2013'd <= Index)) noautolegend;
  title 'VAR Forecast - 2013Q1-2016Q3';
  series x = Index y = Consumption / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = For1 / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "VAR Forecast";
  band x = Index upper=UCI1 lower=LCI1 / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes' values=(-1.5 to 2.5 by 0.5);
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;

/* Bayesian Vector Autoregressive Model */
proc varmax data=us_econ(where=('01JAN1970'd <= Index <= '31DEC2014'd)) plot=all;
  id index interval=quarter;
  model consumption income / p=3 lagmax=5
        print=(estimates diagnose)
        prior=(lambda=0.9 theta=0.1);
  output out=for_bvar lead=7;
run;

data forecasts;
  set forecasts;
  set for_bvar(rename=(for1=for_bvar));
  keep Index Full_Consumption for_esm for_arima for_bar for_var for_bvar;
run;

data bvar_chart;
  set us_econ(rename=(Consumption=Full_Consumption));
  set for_bvar;
run;

proc sgplot data=bvar_chart noautolegend;
  title 'Bayesian VAR Forecast - US Personal Consumption Expenditure';
  series x = Index y = Consumption / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = For1 / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "Bayesian VAR Forecast";
  band x = Index upper=UCI1 lower=LCI1 / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes';
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;

proc sgplot data=bvar_chart(where=('01JAN2013'd <= Index)) noautolegend;
  title 'Bayesian VAR Forecast - 2013Q1-2016Q3';
  series x = Index y = Consumption / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = For1 / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "Bayesian VAR Forecast";
  band x = Index upper=UCI1 lower=LCI1 / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes' values=(-1.5 to 2.5 by 0.5);
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;

/* Calculating Training MAPE for All Models */
data forecasts;
  set forecasts(rename=(Full_Consumption=Consumption));

  for_ensemble = (for_arima + for_bar)/2;

  ESM_APE = abs((for_esm - consumption)/consumption);
  ARIMA_APE = abs((for_arima - consumption)/consumption);
  BAR_APE = abs((for_bar - consumption)/consumption);
  VAR_APE = abs((for_var - consumption)/consumption);
  BVAR_APE = abs((for_bvar - consumption)/consumption);

  ENSEMBLE_APE = abs((for_ensemble - consumption)/consumption);
run;

proc means data=forecasts(where=('01JAN1970'd <= Index <= '31DEC2014'd)) mean;
  var ESM_APE ARIMA_APE BAR_APE VAR_APE BVAR_APE ENSEMBLE_APE;
run;

/* Calculating Testing MAPE for All Models */
proc means data=forecasts(where=('01JAN2015'd <= Index)) mean;
  var ESM_APE ARIMA_APE BAR_APE VAR_APE BVAR_APE ENSEMBLE_APE;
run;

data ensemble_chart;
  set forecasts(rename=(Consumption=Full_Consumption));
  set train;
  set arima_chart;
  set esm_chart;
  set bar_chart;

  ensemble_upper = (U95 + HPDUPPER)/2;
  ensemble_lower = (L95 + HPDLOWER)/2;
run;

proc sgplot data=ensemble_chart noautolegend;
  title 'Ensemble Forecast - US Personal Consumption Expenditure';
  series x = Index y = Consumption / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = for_ensemble / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "Ensemble Forecast";
  band x = Index upper=ensemble_upper lower=ensemble_lower / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes';
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;

proc sgplot data=ensemble_chart(where=('01JAN2013'd <= Index)) noautolegend;
  title 'Ensemble Forecast - US Personal Consumption Expenditure';
  series x = Index y = Consumption / lineattrs = (color = blue) name = "train" legendlabel = "Consumption";
  series x = Index y = Full_Consumption / lineattrs = (color = blue pattern = dot) name = "test" legendlabel = "Hold-out Consumption";
  series x = Index y = for_ensemble / lineattrs = (color = red pattern = dash) name = "for" legendlabel = "Ensemble Forecast";
  band x = Index upper=ensemble_upper lower=ensemble_lower / transparency=.5 name = "CI" legendlabel = "95% Confidence Interval";
  yaxis label='PCE Percent Changes' values=(-1.5 to 2.5 by 0.5);
  xaxis label='Date (Quarterly)';
  keylegend "train" "test" "for" "CI";
run;
