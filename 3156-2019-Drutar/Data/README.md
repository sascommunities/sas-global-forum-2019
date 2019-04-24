# SAS  Viya  reportImages Service: The Report Optimization Speedometer - Example Datasets     

This paper uses three SAS Visual Analytics report in its examples.  Before importing the reports into your SAS Viya platform, you will need to generate the needed data sources.  This can be accomplished by completing the steps below:

## Download the source data from SAS Maps Online

The source data can be downloaded from the  [SAS Maps Online Website](http://support.sas.com/rnd/datavisualization/mapsonline/html/home.html).

Specifically, the [Usroads2009_US zip file](https://support.sas.com/downloads/download.htm?did=104245) is needed.

Once downloaded and extracted, follow the instructions in Readmecpt.txt to extract the SAS dataset "usroads2009.sas7bdat" from the CPT file "usroads2009.cpt."

Place the usroads2009.sas7bdat in a SAS Library accessible to SAS Studio 5.1 on your Viya environment.

## Run SAS ETL to create report source files:

[create_source_data.sas](./create_source_data.sas)

With the usroads2009.sas7bdat in place the SAS code found in this section must be executed in SAS Studio 5.1 on your Viya environment.  It will create the two source files used in this paper:

*  us_roads
*  us_roads_agg





