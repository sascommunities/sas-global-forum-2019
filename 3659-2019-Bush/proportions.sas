%macro Presentation_Code(percent=, sepercent=, p=, sep=, nsum=, df=);
  *p and its standard error should be decimal numbers between 0 and 1 *check if user has entered a percent or a proportion;
  %if &percent^= %then
    %do;
      *convert percent to proportion;
      p=&percent/100;
      sep=&sepercent/100;
      q=1-p;
    %end;
  %else %if &p^= %then
    %do;
      *assume that user has entered a proportion;
      p=&p;
      sep=&sep;
      q=1-p;
    %end;
  nsum=&nsum;
  df_flag=0;

  * check if user entered a df value * if not, then set df to sample(nsum) - 1;
  %if &df= %then
    %do;
      df=nsum-1;
    %end;
  %else
    %do;
      df = &df;
      if df<8 then
        df_flag=1;
    %end;

  *Effective sample size *compute n effective *note: for proportions from vital data files where SE=(p*q)/N, n_eff will equal to N;
  if (0<p<1) then
    n_eff=(p*(1-p))/(sep**2);
  else n_eff=nsum;
  if (n_eff=. or n_eff>nsum) then
    n_eff=nsum;

  *Ratio of ts: adjustment to sample size suggested by Korn and Graubard for complex survey data;
  *A two-sided a (0.05/2 or 0.025) is used in the equation below: 1-0.025 = 0.975;
  if df > 0 then
    rat_squ=(tinv(.975,nsum-1)/tinv(.975,df))**2;
  else rat_squ=0;

  *limit case: set to zero;
  *df-adjusted effective sample size (can be no greater than the sample size);
  if p > 0 then
    n_eff_df=min(nsum,rat_squ*n_eff);
  else n_eff_df=nsum;

  *limit case: set to sample size;
  *Parameters for beta confidence limits;
  x=n_eff_df*p;
  v1=x;
  v2=n_eff_df-x+1;
  v3=x+1;
  v4=n_eff_df-x;

  *lower and upper confidence limits for Korn and Graubard interval *Note: Using inverse beta instead of ratio of Fs for numerical efficiency *if (0<p<1), otherwise set lower limit to 0 when p=0 and upper limit to 1 when p=1
  *A two-sided a (0.05/2 or 0.025) is used in the equations below: 0.025 and
  0.975;
  if (v1=0) then
    kg_l=0;
  else kg_l=betainv(.025,v1,v2);
  if (v4=0) then
    kg_u=1;
  else kg_u=betainv(.975,v3,v4);

  *Korn and Graubard CI absolute width;
  kg_wdth=kg_u - kg_l;

  *Korn and Graubard CI relative width for p;
  if (p>0) then
    kg_relw_p=100*(kg_wdth/p);
  else kg_relw_p=.;

  *Korn and Graubard CI relative width for q;
  if (q>0) then
    kg_relw_q=100*(kg_wdth/q);
  else kg_relw_q=.;

  *Proportions with CI width <= 0.05 are reliable, unless;
  p_reliable=1;

  *Effective sample size is less than 30;
  if n_eff < 30 then
    p_reliable=0;

  *Absolute CI width is greater than or equal 0.30;
  else if kg_wdth ge 0.30 then
    p_reliable=0;

  *Relative CI width is greater than 130%;
  else if (kg_relw_p > 130 and kg_wdth > 0.05) then
    p_reliable=0;

  *Determine if estimate should be flagged as having an unreliable complement;
  if (p_reliable=1) then
    do;
      *Complementary proportions are reliable, unless;
      q_reliable=1;

      *Relative CI width is greater than 130%;
      if (kg_relw_q > 130 and kg_wdth > 0.05) then
        q_reliable=0;
    end;
  p_statistical=0;
  if p_reliable=1 then
    do;
      *Estimates with df < 8 or percents = 0 or 100 or unreliable complement
      are flagged for clerical or ADS review;
      if df_flag=1 or p=0 or p=1 or q_reliable=0 then
        p_statistical =1;
    end;
%mend Presentation_Code;