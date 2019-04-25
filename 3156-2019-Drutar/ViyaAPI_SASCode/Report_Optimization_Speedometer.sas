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
* Input: The Visual Analytics report's datasource (must be sashdat), the report's
*        name and the internal report id (UID) **these inputs are to be placed in 
*        the macro call at the bottom of this program.
*
* Output: ODS table showing the report name, id, reportImages job id and job duration
*
* All code below is intended to be submitted in a SAS Studio 5.1 (or later) 
* session within a SAS Viya 3.4 (or later) environment 
\******************************************************************************/


%macro report_generation_duration(sourcedata,report_name,report_uri);

* Base URI for the service call;
%let BASE_URI=%sysfunc(getoption(servicesbaseurl));

/* Refresh Data in CAS */
cas myses;
proc casutil;
	droptable incaslib="PUBLIC" casdata="&sourcedata" quiet;
	load incaslib="PUBLIC" outcaslib="PUBLIC" casdata="&sourcedata..sashdat" casout="&sourcedata"  promote;
run;

/* create dynamic proc http 'in=' statement  */
data create_params;
	request_params = "'" || trim('{"reportUri" : "') || "&report_uri" || trim('","layoutType" : "entireSection","refresh":true,"selectionType" : "report","size" : "1680x1050","version" : 1}' || "'");
	call symput('request_params',request_params);
run;

/* create job and get response */
filename resp_hdr clear;
filename startjob clear;
libname startjob clear;
filename startjob temp;
filename resp_hdr temp;
proc http 
     oauth_bearer=sas_services
	 method="POST"
	 url="&BASE_URI/reportImages/jobs"
	 ct="application/vnd.sas.report.images.job.request+json"
	 in=&request_params.
	 out=startjob
	 headerout=resp_hdr
     headerout_overwrite;
run;
libname startjob json;

/* capture job id into macro variable job_id */
data _NULL_;
	set startjob.root;
	  call symputx('job_id',id);
run;

/* Stet initial &status to be zero */
%let status=0;

/* macro to check status until job is completed */
%macro jobstatus;
	   %do %until (&status ne 0);
		filename res_hdr clear;    	
		filename j_status clear;
	      libname j_status clear;
		filename j_status temp;
		filename res_hdr temp;
	/* Make API Call	 */
		proc http 
		     oauth_bearer=sas_services	 
		     method="GET" 
			 url="&BASE_URI/reportImages/jobs/&job_id"
			 out=j_status
			 headerout=res_hdr
 			 headerout_overwrite;
		run;
	
		libname j_status json;
	
		/* create &status macro variable */
		data job_status;
			set j_status.root;
				if state = 'running' then status = 0;
				else if state = 'completed' then status = 1;
				call symputx('status',status);
		run;

		/* Wait one second */
		data _NULL_;
		   time_slept=sleep(1,1);
		run;

	
	%end;
%mend jobstatus;

/* call macro %jobstatus */
%jobstatus;

/* create and print final dataset data set */
data report;
	set j_status.root;
		reportName = "&report_name";
		reportURI = "&report_uri";
		label id = "reportImages Job ID"
		duration = "Job Duration"
		label state="Job Status";
run;

/* Print output */
title "reportImages Duration - Report: '&report_name'";
proc print data= report noobs label;
	var reportName reportURI id state duration;
run;

%mend report_generation_duration;

/* -------------------------------------------------------------- */
/*                  Call the macro on two reports                 */
/* -------------------------------------------------------------- */

%report_generation_duration(us_roads,Parkway Roads - Source Data,/reports/reports/c199d225-a536-44c9-a9c3-5d9e19aac6cc);
%report_generation_duration(us_roads_agg,Parkway Roads - Aggregated Data,/reports/reports/e3704e78-2316-48b3-9f25-a056a2bccc3f);
