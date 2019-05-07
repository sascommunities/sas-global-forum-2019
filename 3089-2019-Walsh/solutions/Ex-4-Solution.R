#################################################################################
# DESCRIPTION: Examples of how to write R code that runs on CAS
#
# INPUT: NA
#
# OUTPUT: NA
#
# AUTHOR: EW
#
# DEPENDENCIES: 
# swat package must be installed
# authinfo file must contain credentials to connect to the server
# D:\Workshop\HOW\data\cas_crash.csv must exist
#
# NOTES:
# code is versioned and publicly available so the credentials have been ommited
# you will need to specify the server name and port number prior to running this
#
# HISTORY:
# 13 Apr 2019 EW updated after testing on image
# 12 Feb 2019 EW v1
#################################################################################


#### setup ####

# Exercise 4a enter the name of the package
# load the swat package so that R can interface with CAS
library(swat)
options(cas.trace.actions = FALSE)
options(cas.print.messages = TRUE)

# location where the data is stored
setwd("D:/Workshop/HOW/data")

#### load data ####
# Exercise 4a - connecting to CAS
conn2cas <- CAS("server-name", port_number, protocol="http")
cas.builtins.about(conn2cas)

# load dataset into memory
castbl_cas_crash <- cas.read.csv(conn2cas, "cas_crash.csv")

# in some functions you need to pass the name of the table not the CASTable object
table_name_str <- 'cas_crash'

#### prep data ####
# Exercise 4b
listActionSets(conn2cas)$actionset
loadActionSet(conn2cas, 'decisionTree')

# load the action sets for sampling and imputation respectively
loadActionSet(conn2cas, 'sampling')
loadActionSet(conn2cas, 'dataPreprocess')

# create a set of variables to easily refer to the different types of variable roles
# identify the name of the column to help us distinguish the different types of variables
colinfo <- cas.table.columnInfo(conn2cas, table = table_name_str)$ColumnInfo
head(colinfo)

# Target variable is the last column 
target_var <- colinfo$Column[ncol(castbl_cas_crash)] 

# all the variables to model, make sure the id and target are not inputs to the model
input_vars <- colinfo$Column[-c(1, ncol(castbl_cas_crash))] 

# all the categorical variables
# note that searching for a varchar type here has its limits if some of
# the categorical variables are labelled 1, 2, 3, 4
nominal_vars <- c(target_var, subset(colinfo, Type == 'varchar')$Column)

# names for the imputed vars which we will prefix with IMP_ downstream
input_vars_imp <- paste0('IMP_', input_vars)
nominal_vars_imp <- c(target_var, paste0('IMP_', nominal_vars[-1]))

# partition data into train, validation and test
cas.sampling.srs(conn2cas, 
                 table    = table_name_str, 
                 samppct  = 70, 
                 samppct2 = 20,
                 SEED     = 12345, 
                 partind  = TRUE,
                 output   = list(casOut = list(name = table_name_str, replace = TRUE),
                                 copyVars = 'ALL')
)


# impute missing values
cas.dataPreprocess.impute(castbl_cas_crash,
                             outVarsNamePrefix = 'IMP',
                             methodContinuous = 'MEDIAN',
                             methodNominal = 'MODE',
                             inputs = colnames(castbl_cas_crash)[-ncol(castbl_cas_crash)],
                             copyAllVars = TRUE,
                             casOut = list(name = table_name_str, replace = TRUE)
)

#### create model ####
# Exercise 4c
cas.decisionTree.forestTrain(conn2cas,
                             table    = list(name = table_name_str, where = '_PartInd_ = 1'),
                             target   = target_var,
                             inputs   = input_vars,
                             nominals = nominal_vars,
                             nTree    = 100,
                             casOut   = list(name = 'random_forest_model', replace = TRUE)
)

#### analyse R data frame vs CAS object ####
# Exercise 4d
# bring the data to the client so that you can use packages like ggplot2 and xgboost
cas_crash_df <- to.casDataFrame(castbl_cas_crash)

# check the class types of each object
class(castbl_cas_crash)
class(cas_crash_df )

# check how many  of the rows came through to the client vs how many are in the CAS table object
dim(castbl_cas_crash)
dim(cas_crash_df)

#### tidy up ####

# disconnect from CAS
cas.session.endSession(conn2cas)
