/* ---- SAS macro uses Iman-Conover method to generate multivariate data ---- */
%include "Generate_RandomMV_Data.sas";  /* put this file in the same folder as mainProgram.sas */

/* ---- Correlation Structure for Multivariate Data ----*/
%let Corr = { 1.00  0.90 0.90 0.90,
	   		0.90  1.00 0.90 0.90,
	  		0.90  0.90 1.00 0.90,
	   		0.90  0.90 0.90 1.00 };

/* ---- List of Marginal Distribution for Multivariate Data ----*/
%let L1 = {'LOGNORMAL' 'PARETO' 'NORMAL' 'UNIFORM'};
%let L2 = {'LOGNORMAL' 'NORMAL' 'EXPONENTIAL' 'UNIFORM'};

/* ---- Miscellaneous settings ----*/
%let misList = (4,8,33,39,59); /* The items to be set as missing values */
%let NSIM=1000; /* The number of simulation for generating multivariate data in back-transforming step */
%let misVar = x1; /* Variable corresponding to missing value  "Y" */
%let ccVarList = x2 x3 x4; /* Variables corresponding to the fully observed values (vector "X") */

%genMVdata(seed=123, nSize=100, nvar=4, distList=&L1, corrMat=%superq(Corr), logNormSigma=1.0, Pareto_a=1.0, out=rawMV);

/* Create missing value by removing X1 values in misList */
data misData;
		set rawMV;
		Sr = _n_;
		mis_raw = &misVar;
		Flag = 'X';
		if Sr in &misList then do;
			Flag = '.'; &misVar = .; 
		end;
run;

/* The raw data with missing values is in file misData.*/
/* If you have missing data provide here instead of generating as we did above using Iman-Conover method,
replace it by your raw missing data. Accordingly, modify the misVar and ccVarList and their corresponding setting
in the following procedues.*/

/* -------------- Step 1 & 2 ---------------
----- Transform complete cases and incomplete cases in misData
----- to uniform random variables*/

proc copula data=misData(where=(Flag='X')); /* Flag="X" indicates observed values and Flag="." indicates missing values */
  var &misVar &ccVarList;
  fit normal / marginals=empirical outpseudo=unif_cc noprint;
run;
	
proc copula data=misData;
  var &ccVarList;
  fit normal / marginals=empirical outpseudo=unif_ic noprint;
run;
	
data unif_cc_star;
  set unif_cc;
  Flag = 'X';
run;
	
data unif_ic_star(where=(Flag='.')); /* Flag="X" indicates observed values and Flag="." indicates missing values */
merge unif_ic misData(keep=Flag);
run;

/* -------------- Step 3 ---------------
----- Combine two datasets unif_cc_star and unif_ic_star and 
transform each of uniformly distributed column data to 
standard normal by using quantile function */

data unif_u;
  set unif_cc_star unif_ic_star;
run;

data std_norm;
  set unif_u;
  if Flag='X' then x1 = quantile("Normal", x1);
  x2 = quantile("Normal", x2);
  x3 = quantile("Normal", x3);
  x4 = quantile("Normal", x4);
run;

/* -------------- Step 4 ---------------
----- Apply the desired multiple imputation method on the dataset std_norm. 
MCMC method is selected as an example in the code given below. */

proc mi data=std_norm nimpute=5 out=mi_std_norm seed=1234 noprint;
  mcmc;
  var &misVar &ccVarList;
run;

/* -------------- Step 5 ---------------
----- Back-transform the filled-in data to original scale according to the copula */

/* -----Step 5 (a)-----
Simulate a large number (e.g., NSIM=1,000) of observations from 
multivariate uniform distribution corresponding to our copula and 
convert those simulated observations to the data on variables in 
original data scale and to the data on variables with 
standard normal distribution, respectively. */

proc copula data=misdata(where=(Flag='X'));
  var &misVar &ccVarList;
  fit normal / marginals=empirical noprint;
  simulate /ndraws = &NSIM seed=1234567
  out = sim_org outuniform=sim_unif;
run;

data sim_std_norm;
  set sim_unif;
  sx1 = quantile("Normal", x1);
  sx2 = quantile("Normal", x2);
  sx3 = quantile("Normal", x3);
  sx4 = quantile("Normal", x4);
  keep sx1 sx2 sx3 sx4;
run;

/* -----Step 5 (b)-----
Obtain the imputed values in original data scale by 
interpolation from above simulated observations 
in data sets sim_org and sim_std_norm. */
data sim_org;
  set sim_org;
  keep x1;
  rename x1=rx1;
run;

data sim_std_norm(keep=sx1);
  set sim_std_norm;
run;

proc sort data=sim_std_norm; by sx1; run;
proc sort data=sim_org; by rx1; run;

data sim_org_std;
  merge sim_std_norm sim_org;
run;

/* filter the imputed values in variable x1*/
data impt_std_norm;
  set mi_std_norm(where=(Flag='.'));
  keep _Imputation_ x1;
  rename x1=sx1;
run;

data impt_sim_comb;
  set impt_std_norm sim_org_std;
run;

proc sort data=impt_sim_comb; by sx1; run;

data impt_org_scale;                                                 
  merge impt_sim_comb impt_sim_comb(keep=rx1 firstobs=2 rename=(rx1=lead_mis));     
  lag_mis=lag(rx1);       
  if rx1=. then do;
  rx1=mean(lag_mis, lead_mis);  
  MIS='Y';
  end;
run;

data impt_org_scale_ic;
	set impt_org_scale;
	where MIS='Y';
run;

proc sort data=impt_org_scale_ic; by sx1; run;

/* Display the imputed data */
data mi_std_norm_ic;
	set mi_std_norm;
	where Flag='.';
	Sr = _n_;
	rename x1=sx1 x2=sx2 x3=sx3 x4=sx4;
run;

proc sort data=mi_std_norm_ic; by sx1; run;

data impt_data;
	merge mi_std_norm_ic impt_org_scale_ic;
	by sx1;
	keep Sr _imputation_ rx1 sx1-sx4 Flag MIS;
run;

proc sort data=impt_data; by Sr; run;

proc print data=impt_data;
run;
