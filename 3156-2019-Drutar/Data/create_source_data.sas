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
* Input: The location of the source dataset 'USROADS2009.sas7bdat', the CASLIB 
*        that the dataset and hdat file will be created in
*
* Output: CAS Datsets: us_roads & us_roads_agg, hdat files: us_roads.sashdat &
*         us_roads_agg.sashdat
*
* All code below is intended to be submitted in a SAS Studio 5.1 (or later) 
* session within a SAS Viya 3.4 (or later) environment 
\******************************************************************************/

/* Input location of extracted usroads2009.sas7bdat file */
libname sasfiles '<- location of source data ->';

/* Input Target CAS Library (Public is the default) */
%let CAS_LIB = PUBLIC;


/* Create CAS Session */
cas myses;


/* simple macro to create sashdat file*/
%macro createHdat(dataset);
data _NULL_;
call symput('casdata_out',scan("&dataset",-1,'.'));
run;
proc casutil;
droptable casdata="&casdata_out" incaslib="&CAS_LIB" quiet;
load data=&dataset. outcaslib="&CAS_LIB";
save incaslib="&CAS_LIB" outcaslib="&CAS_LIB" casdata="&casdata_out" replace;
droptable casdata="&casdata_out" incaslib="&CAS_LIB" quiet;
load incaslib="&CAS_LIB" outcaslib="&CAS_LIB" casdata="&casdata_out..sashdat" casout="&casdata_out" promote;
run;
%mend createHdat;


/* -------------------------------------------------------------- */
/*               Create large us_roads data                       */
/* -------------------------------------------------------------- */

/* add statename to USROADS2009 dataset */
proc sql;
create table us_roads as select
t1.*,
t2.statecode,
t2.statename
from SASFILES.USROADS2009 as t1
left join  maps.US2 as t2
on (t1.state=t2.state);
quit;

/* create hdat */
%createHdat(work.us_roads);

/* -------------------------------------------------------------- */
/*             Create aggregrated us_roads_agg data               */
/* -------------------------------------------------------------- */

/* locate all road names that contain "PARKWAY" in their names and flag them */
data create_flag;
set us_roads;
if index(upcase(FULLNAME),"PARKWAY")>0 then Parkway_Roads = 1;
else  Parkway_Roads = 0;
run;

/* Total up roads the Parkway_Roads flag */
proc sql;
create table us_roads_agg as select
statename,
statecode,
sum(Parkway_Roads) as Parkway_Roads format=comma8. label = "Parkway Roads"
from create_flag
where statecode not in ("HI","AK")
group by statename, statecode;
quit;

/* create hdat */
%createHdat(us_roads_agg);