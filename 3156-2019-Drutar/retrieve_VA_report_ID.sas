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
* Input: Viya Environment http (or https) address, Name of the report
* 
*
* Output: PROC PRINT'S output displaying the name(s) and ID(s) of the report(s)
*
*
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

/* Print the report name and ID */
proc print data=rep_id.items noobs label;
label name='Report Name' id='Report Internal ID';
var name id;
run;
