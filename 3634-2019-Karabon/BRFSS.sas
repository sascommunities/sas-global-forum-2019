%LET FILEPATH = Z:\Documents\Faculty Research\Patrick Karabon\Propensity Score and Complex Samples;
LIBNAME OUTPATH "&FILEPATH.";

/********************************************************************
Task: Convert the SAS Transport BRFSS 2016 file to a SAS7BDAT file
using PROC XCOPY.
Users should also note that there is an ASCII file that can be read
in as well; hoewever, it is easiest to read in the SAS Transport
format
URL: https://www.cdc.gov/brfss/annual_data/annual_2016.html
Codebook: https://www.cdc.gov/brfss/annual_data/2016/pdf/codebook16_llcp.pdf
********************************************************************
PROC XCOPY IN = IN2016 OUT = OUTPATH IMPORT;
RUN;
/********************************************************************
Task: Cleaning the 2016 BRFSS Data in order to get the variables
necessary for analysis
I proivde details on each of the variables created from the data in
order to maintain transparency.
All binary variables are coded as 1 for "Yes" and 0 for "No"
********************************************************************/
DATA WORK.BRFSS;
  SET OUTPATH.LLCP2016;

  /****************************************************************
  Creating the binary Yes/No variable FLUSHOT from the BRFSS
  variable FLUSHOT6.
  FLUSHOT6 Question: "During the past 12 months, have you had either
  a flu short or a flu vaccine that was sprayed in your nose? (A new
  flu shot came out in 2011 that injects vaccine into the skin with
  a very small needle. It is called Fluzone Intradermal vaccine.
  This is also considered a flu shot.)"
  ****************************************************************/
  FLUSHOT = 0;
  IF (FLUSHOT6 = 1) THEN
    FLUSHOT = 1;

  /****************************************************************
  Creating the binary Yes/No variable MARRIED from the BRFSS
  variable MARITAL.
  MARITAL Question: "What is your marital status?"
  ****************************************************************/
  MARRIED = 0;
  IF (MARITAL = 1) THEN
    MARRIED = 1;

  /****************************************************************
  Renaming the variable _AGE80 to AGE. This is due to personal
  preference of avoiding the underscores in the variable name.
  ****************************************************************/
  RENAME _AGE80 = AGE;

  /****************************************************************
  Creating the binary Yes/No variables BLACK and Hispanic from
  the BRFSS variable _RACE to indiciate Non-Hispanic Black and
  Hispanic respondents, respectively.
  _RACE Question: "What is your race/ethnicity?"
  ****************************************************************/
  BLACK = 0;
  HISPANIC = 0;
  IF (_RACE = 2) THEN
    BLACK = 1;
  IF (_RACE = 8) THEN
    HISPANIC = 1;

  /****************************************************************
  Creating the binary Yes/No variable HSGRAD from the BRFSS variable
  _EDUCAG to indicate respondents who have graduated high school
  _EDUCAG Question: "What is the highest level of education you
  completed?"
  ****************************************************************/
  HSGRAD = 0;
  IF (_EDUCAG IN (2, 3, 4)) THEN
    HSGRAD = 1;

  /****************************************************************
  Creating the binary Yes/No variable POVERTY from the BRFSS
  variable _INCOMG to indicate respondents who have income < $25,000.
  _INCOMG Question: "What is your income?"
  ****************************************************************/
  POVERTY = 0;
  IF (_INCOMG IN (1, 2)) THEN
    POVERTY = 1;

  /****************************************************************
  Creating the binary Yes/No variable SMOKER from the BRFSS variable
  _SMOKER3 to indicate respondents who currently smoke.
  _SMOKER3 Question: "What is your smoking status?"
  ****************************************************************/
  SMOKER = 0;
  IF (_SMOKER3 = 1) THEN
    SMOKER = 1;

  /****************************************************************
  Creating the binary Yes/No variable DOCTOR from the BRFSS variable
  PERSDOC2 to indicate respondents who currently have a regular
  doctor (implying access to care).
  PERSDOC2 Question: "Do you have on person you think of as your
  personal doctor of health care provider?"
  ****************************************************************/
  DOCTOR = 0;
  IF (PERSDOC2 IN (1, 2)) THEN
    DOCTOR = 1;

  /****************************************************************
  Creating the binary Yes/No variable INSURANCE from the BRFSS
  variable HLTHPLN1 to indicate respondents who currently have
  some form of health insurance.
  HLTNPLN1 Question: "Do you have any kind of health care coverage,
  inclduing health insurance, prepaid plans such as HMOs, or
  government plans such as Medicare, or Indian Health Service?"
  ****************************************************************/
  INSURANCE = 0;
  IF (HLTHPLN1 = 1) THEN
    INSURANCE = 1;

  /****************************************************************
  Creating the binary Yes/No variable BADHEALTH from the BRFSS
  variable GENHLTH to indicate respondents who self-reported
  Fair or Poor General Health.
  GENHLTH Question "Would you say your general health is?"
  ****************************************************************/

  /* Create Indicator for Fair/Poor Health */
  BADHEALTH = 0;
  IF (GENHLTH IN (4, 5)) THEN
    BADHEALTH = 1;
RUN;

/********************************************************************
Task: Keeping/Retaining only the variabes necesary for analaysis.
With over 1,000,000 records and 275 variables, data processes can
become computationally intensive depending on the capacity of the
system being utilized. This process does require merging propensity
scores with the BRFSS dataset.
********************************************************************/
DATA BRFSS;
  SET BRFSS
    (KEEP = SEQNO FLUSHOT MARRIED BLACK HISPANIC HSGRAD POVERTY
    SMOKER DOCTOR INSURANCE BADHEALTH _STSTR _LLCPWT
    _PSU);
RUN;

/********************************************************************
Modeling Using Logistic Regression for Complex Survey Data
Both a Univariate Model and a Multivariate Model
Models are weighted by the BRFSS-provided weights (_LLCPWT) and
include the cluster (_PSU) and strata (_STSTR) variables provided.
********************************************************************/

/* Univariate Model to explore possible association between being
Married and receiving a Flu shot*/
PROC SURVEYLOGISTIC DATA = BRFSS;
  STRATA _STSTR;
  WEIGHT _LLCPWT;
  CLUSTER _PSU;
  CLASS FLUSHOT(REF = "0") MARRIED(REF = "0") / PARAM = GLM;
  MODEL FLUSHOT = MARRIED;
RUN;

/* Multivariate Model to explore possible association between being
Married and receiving a Flu shot while controlling for possible
confounding variables in the BRFSS dataset. */
PROC SURVEYLOGISTIC DATA = BRFSS;
  STRATA _STSTR;
  WEIGHT _LLCPWT;
  CLUSTER _PSU;
  CLASS FLUSHOT(REF = "0") MARRIED(REF = "0") BLACK HISPANIC HSGRAD POVERTY
    SMOKER DOCTOR INSURANCE BADHEALTH / PARAM = GLM;
  MODEL FLUSHOT = MARRIED BLACK HISPANIC HSGRAD POVERTY SMOKER DOCTOR INSURANCE
    BADHEALTH;
RUN;

/********************************************************************
Comparing Variables between MARRIED to look at the magnitude of
associations between potential confounding variables and being married.
********************************************************************/
PROC SURVEYFREQ DATA = BRFSS;
  STRATA _STSTR;
  WEIGHT _LLCPWT;
  CLUSTER _PSU;
  TABLES BLACK*MARRIED / CHISQ;
  TABLES HISPANIC*MARRIED / CHISQ;
  TABLES HSGRAD*MARRIED / CHISQ;
  TABLES POVERTY*MARRIED / CHISQ;
  TABLES SMOKER*MARRIED / CHISQ;
  TABLES DOCTOR*MARRIED / CHISQ;
  TABLES INSURANCE*MARRIED / CHISQ;
  TABLES BADHEALTH*MARRIED / CHISQ;
RUN;

/********************************************************************
Task: Performing Propensity Score IPTW/ATE Weighting
********************************************************************/

/* Running the propensity score model using PROC PSMATCH to get the
variable balance assessment measures and creating an output
dataset ATE that contains the ATE weights as the variable _ATE_ */
PROC PSMATCH DATA = BRFSS REGION = ALLOBS;
  CLASS MARRIED BLACK HISPANIC HSGRAD POVERTY SMOKER DOCTOR INSURANCE
    BADHEALTH;
  PSMODEL MARRIED(TREATED = "1") = BLACK HISPANIC HSGRAD POVERTY
    SMOKER DOCTOR INSURANCE BADHEALTH _LLCPWT;
  ASSESS PS VAR = (BLACK HISPANIC HSGRAD POVERTY SMOKER DOCTOR
    INSURANCE BADHEALTH _LLCPWT)
    / VARINFO PLOTS = ALL WEIGHT = ATEWGT;
  OUTPUT OUT(OBS = ALL) = ATE ATEWGT = _ATE_;
RUN;

/* Modifying the dataset containing the weights to only contain the ID
number and the IPTW/ATE weights. This is done to avoid bringing
additional information over to the further steps.*/
DATA ATE;
  SET ATE
    (KEEP = SEQNO _ATE_);
RUN;

/* Sorting both the dataset containing the weights (ATE) and the main
dataset (BRFSS) prior to merging the two datasets */
PROC SORT DATA = ATE;
  BY SEQNO;
RUN;

PROC SORT DATA = BRFSS;
  BY SEQNO;
RUN;

/* Merging the main dataset (BRFSS) and the dataset containing the
weights from PROC PSMATCH (ATE) using the BRFSS-provided case
identification number (SEQNO).
Also, multiplying the ATE/IPTW weight and the dataset-provided
sampling weight in order to get a final weight, which in this
case is the variable ATE */
DATA BRFSS;
  MERGE BRFSS ATE;
  BY SEQNO;
  ATE = _ATE_*_LLCPWT;
RUN;

/* Running the Outcome Model using PROC SURVEYLOGISTIC. Note the
final weight ATE calculated in the prior data step was used
in this model. */
PROC SURVEYLOGISTIC DATA = BRFSS;
  STRATA _STSTR;
  WEIGHT ATE;
  CLUSTER _PSU;
  CLASS FLUSHOT(REF = "0") MARRIED(REF = "0") BLACK HISPANIC HSGRAD
    POVERTY SMOKER DOCTOR INSURANCE BADHEALTH / PARAM = GLM;
  MODEL FLUSHOT = MARRIED BLACK HISPANIC HSGRAD POVERTY SMOKER
    DOCTOR INSURANCE BADHEALTH;
RUN;

/********************************************************************
Task: Performing Propensity Score ATT Weighting (Weighting by Odds)
The syntax for the PSMATCH procedure is nearly identical as when
performing IPTW/ATE weighting; however, the WEIGHT option in the
assess statement and the output statement are slightly modified.
********************************************************************/

/* Running the propenisty score model using PROC PSMATCH to get the
variable balance assessment measures and creating an output
dataset called ATT that contains the ATT weights as the variable
_ATT_ */
PROC PSMATCH DATA = BRFSS REGION = ALLOBS;
  CLASS MARRIED BLACK HISPANIC HSGRAD POVERTY SMOKER DOCTOR INSURANCE
    BADHEALTH;
  PSMODEL MARRIED(TREATED = "1") = BLACK HISPANIC HSGRAD POVERTY
    SMOKER DOCTOR INSURANCE BADHEALTH _LLCPWT;
  ASSESS PS VAR = (BLACK HISPANIC HSGRAD POVERTY SMOKER DOCTOR
    INSURANCE BADHEALTH _LLCPWT)
    / VARINFO PLOTS = ALL WEIGHT = ATTWGT;
  OUTPUT OUT(OBS = ALL) = ATT ATTWGT = _ATT_;
RUN;

/* Modifying the dataset containing the weights to only contain the ID
number and the ATT weights. This is done to avoid bringing
additional information over to the further steps. */
DATA ATT;
  SET ATT
    (KEEP = SEQNO _ATT_);
RUN;

/* Sorting both the dataset containing the weights (ATT) and the main
dataset (BRFSS) prior to merging the two datasets */
PROC SORT DATA = ATT;
  BY SEQNO;
RUN;

PROC SORT DATA = BRFSS;
  BY SEQNO;
RUN;

/* Merging the main dataset (BRFSS) and the dataset containing the
weights from PROC PSMATCH (ATT) using the BRFSS-provided case
identification number (SEQNO).
Also, multiplying the ATT weight and the dataset-provided
sampling weight in order to get a final weight, which in this
case is the variable ATT */
DATA BRFSS;
  MERGE BRFSS ATT;
  BY SEQNO;
  ATT = _ATT_*_LLCPWT;
RUN;

/* Running the Outcome Model using PROC SURVEYLOGISTIC. Note the
final weight ATT calculated in the prior data step was used
in this model */
PROC SURVEYLOGISTIC DATA = BRFSS;
  STRATA _STSTR;
  WEIGHT ATT;
  CLUSTER _PSU;
  CLASS FLUSHOT(REF = "0") MARRIED(REF = "0") BLACK HISPANIC HSGRAD
    POVERTY SMOKER DOCTOR INSURANCE BADHEALTH / PARAM = GLM;
  MODEL FLUSHOT = MARRIED BLACK HISPANIC HSGRAD POVERTY SMOKER
    DOCTOR INSURANCE BADHEALTH;
RUN;

/********************************************************************
Task: Propensity Score Stratification
The main difference in syntax from the weighting methods is the
inclusion of the STRATA statement in PROC PSMATCH. The statement
NSTRATA = 5 means that we want propensity score quintiles.
********************************************************************/

/* Running the propensity score model using PROC PSMATCH to get the
variable balance assessment measures and creating an output
dataset called STRATA that contains the propensity score strata
as the variable _STRATA_ */
PROC PSMATCH DATA = BRFSS REGION = ALLOBS;
  CLASS MARRIED BLACK HISPANIC HSGRAD POVERTY SMOKER DOCTOR INSURANCE
    BADHEALTH;
  PSMODEL MARRIED(TREATED = "1") = BLACK HISPANIC HSGRAD POVERTY
    SMOKER DOCTOR INSURANCE BADHEALTH _LLCPWT;
  STRATA NSTRATA = 5;
  ASSESS PS VAR = (BLACK HISPANIC HSGRAD POVERTY SMOKER DOCTOR
    INSURANCE BADHEALTH _LLCPWT)
    / VARINFO PLOTS = ALL WEIGHT = ATEWGT;
  OUTPUT OUT(OBS = ALL) = STRATA STRATA = _STRATA_;
RUN;

/* Modifying the dataset containing the strata to only contain the ID
number and the strata number. This is done to avoid bringing
additional information over to the further steps. */
DATA STRATA;
  SET STRATA
    (KEEP = SEQNO _STRATA_);
RUN;

/* Sorting both the dataset containing the strata (STRATA) and the
main dataset (BRFSS) prior to merging the two datasets */
PROC SORT DATA = STRATA;
  BY SEQNO;
RUN;

PROC SORT DATA = BRFSS;
  BY SEQNO;
RUN;

/* Merging the main dataset (BRFSS) and the dataset containing the
strata from PROC PSMATCH (STRATA) using the BRFSS-provided case
identification number (SEQNO) */
DATA BRFSS;
  MERGE BRFSS STRATA;
  BY SEQNO;
RUN;

/* Get Frequencies for PS Strata in order to build a table containing
the estimates for each individual strata*/
PROC SURVEYFREQ DATA = BRFSS;
  STRATA _STSTR;
  WEIGHT _LLCPWT;
  CLUSTER _PSU;
  TABLES MARRIED*_STRATA_;
RUN;

/* Running a PROC SURVEYLOGISTIC model to obtain estimates for each
propensity score Strata to ensure there is homogeneity across the
strata. Note that the STRATA variable (_STRATA_) is placed in the
domain statement. */
PROC SURVEYLOGISTIC DATA = BRFSS;
  STRATA _STSTR;
  WEIGHT _LLCPWT;
  CLUSTER _PSU;
  DOMAIN _STRATA_;
  CLASS FLUSHOT(REF = "0") MARRIED(REF = "0") BLACK HISPANIC HSGRAD
    POVERTY SMOKER DOCTOR INSURANCE BADHEALTH / PARAM = GLM;
  MODEL FLUSHOT = MARRIED BLACK HISPANIC HSGRAD POVERTY SMOKER
    DOCTOR INSURANCE BADHEALTH;
RUN;

/* Running a seperate PROC SURVEYLOGISTIC to obtain a combined estimate
for the straticiation model. Note that _STRATA_ is included as a
covariate in this model. */
PROC SURVEYLOGISTIC DATA = BRFSS;
  STRATA _STSTR;
  WEIGHT _LLCPWT;
  CLUSTER _PSU;
  CLASS FLUSHOT(REF = "0") MARRIED(REF = "0") _STRATA_ BLACK HISPANIC HSGRAD
    POVERTY SMOKER DOCTOR INSURANCE BADHEALTH / PARAM = GLM;
  MODEL FLUSHOT = MARRIED _STRATA_ BLACK HISPANIC HSGRAD POVERTY SMOKER
    DOCTOR INSURANCE BADHEALTH;
RUN;