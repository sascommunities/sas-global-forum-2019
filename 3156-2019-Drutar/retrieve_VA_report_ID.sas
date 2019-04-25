/******************************************************************************\
* Copyright 2019 SAS Institute Inc.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* https://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* Author: Michael Drutar
*
* Input: The Name of a Visual Analytics report
*
* Output: PROC PRINT'S output displaying the name(s) and ID(s) of the report(s)
*
* All code below is intended to be submitted in a SAS Studio 5.1 (or later) 
* session within a SAS Viya 3.4 (or later) environment which contains the  
* SAS Viya services that are being called.
\******************************************************************************/


* Base URI for the service call;
%let BASE_URI=%sysfunc(getoption(servicesbaseurl));

/* Create Macro Variable 'report_name' for the name of the report */
/* Input a report name to search for. */  
/* By default, this code returns report(s) Named "Retail Insights"  */
%let report_name = %sysfunc(urlencode(Retail Insights));

/* Create filename for response */
filename  rep_id temp;

/* Make the request */
	proc http 
	 method="GET"
       oauth_bearer=sas_services
	 url="&BASE_URI/reports/reports?filter=eq(name,'&report_name')"
	 out=rep_id;
	run;

/* read in the response */
libname rep_id json;

/* Print out the list of reports */
/* If no reports were found, print a message */
options mprint mlogic symbolgen;
%macro checkds(dsn);
   %if %sysfunc(exist(&dsn)) %then %do;
	title "The Following Report(s) With The Name '%sysfunc(urldecode(&report_name))' Were Found!";
	proc print data=rep_id.items label;
	label name='Report Name' id='Report Internal ID';
	var name id;
	run;
	title;
   %end;
   %else %do;
      data _null_;
         file print;
         put #3 @10 "No Reports With The Name '%sysfunc(urldecode(&report_name))' Were Found!";
      run;
   %end;
%mend checkds;
%checkds(rep_id.items_links)
