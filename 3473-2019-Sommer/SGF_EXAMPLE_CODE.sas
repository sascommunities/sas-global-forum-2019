******************************************************************************************;
*  Copyright (c) 2019 by SAS Institute, Inc., Cary, NC, USA.                             *;
*  All rights reserved.                                                                  *;
******************************************************************************************;
*  NAME:        dcm_call_rest_service.sas                                                *;
*  DESCRIPTION: Centralized macro for PROC HTTP invocations                              *;
*  OWNER:       Carl Sommer - SAS Institute                                              *;
******************************************************************************************;
%macro dcm_call_rest_service(service=,    /* REST API endpoint                 */
                             method=,     /* GET | PUT | POST | PATCH | DELETE */
                             request=,    /* fileref for PROC HTTP IN=         */
							 response=,   /* fileref for PROC HTTP response    */
							 headers=,    /* HTTP request headers              */
							 headerout=); /* fileref for headerout             */
						
   %local _opt_qlen;
   %local _reqestedURL;
 
   %let _opt_qlen = %sysfunc(getoption(quotelenmax));
   options noquotelenmax;
      %let servernm=%sysfunc(getoption(SERVICESBASEURL));
     
   %if (@&RESPONSE@ eq @@) %then %do;
      filename out temp;
   %end;
   
   %* make sure the servernm does not end in a /, since the requestURL will have that;
   %if ((%qsubstr(&servernm,%length(&servernm),1)) eq %str(/)) %then %do;
     %let servernm = %qsubstr(&servernm,1,%eval(%length(&servernm)-1));
   %end;

   %* Replace backslash \ with slash /, because REST endpoint does not support backslash ;
   %let serverNM=%sysfunc(tranwrd(&serverNM,%str(\),%str(/)));
   %let _requestedURL = %nrbquote(&serverNM.&service);
   	
   proc http OAUTH_BEARER= SAS_SERVICES
   	  %if @&request@ ne @@ %then %do;
        in=&request
	  %end;
	  %if @&response@ eq @@ %then %do;
        out=out 
	  %end;
	  %else %do;
	    out=&response
	  %end;
	  
      url= "&_requestedURL"
	  method= "&method" 
	  %if @&headerout@ ne @@ %then %do;
        headerout=&headerout 
	  %end;
	  ;

	  %if @&headers@ ne @@ %then %do;
        headers &headers ;
	  %end;
   run;   

   %if (%sysfunc(fileref(out)) LE 0) %then %do;
	  filename out clear;
	%end;
  %exit:
	options &_opt_qlen;
 %mend dcm_call_rest_service;

 
******************************************************************************************;
*  Copyright (c) 2019 by SAS Institute, Inc., Cary, NC, USA.                             *;
*  All rights reserved.                                                                  *;
******************************************************************************************;
*  NAME:        dcm_get_code.sas                                                         *;
*  DESCRIPTION: Utility macro to generate and execute requested code.                    *;
*  OWNER:       Carl Sommer - SAS Institute                                              *;
******************************************************************************************;
%macro dcm_get_code(URI=, codeType=, inputTable=, inputTableList=, outputTable=, promote=YES);  
   
   %* determine the REST endpoint and examine the code type ;
   %let restEndpoint = &URI./analysisCode;
   %let contentType  = %str("application/json");
 
   %let codeType = %upcase(&codeType);  %* For simpler comparisons later ;
   %if &codeType eq EXECUTION %then %do;
      %let restEndpoint = &URI./mappedCode;
	  %let contentType  = %str("application/vnd.sas.score.code.generation.request.unbound+json");
   %end;
   %else %if &codeType eq RULEFIRE_DETAIL       %then %let analysisCodeType = %str(ruleFiredDetails);
   %else %if &codeType eq RULEFIRE_SUMMARY      %then %let analysisCodeType = %str(ruleFiredSummary);
   %else %if &codeType eq DECISION_PATH_NODES   %then %let analysisCodeType = %str(decisionPathNodes);
   %else %if &codeType eq DECISION_NODES_COUNTS %then %let analysisCodeType = %str(decisionNodesCounts);
   %else %if &codeType eq DECISION_NODES_FREQ   %then %let analysisCodeType = %str(decisionPathFrequency);

   %* Parse out library and table names ;
   %if &codeType eq DECISION_NODES_COUNTS %then %do;
     %let pathInfo = %qscan(&inputTableList,1,' ');
     %let pathLib = %qscan(%nrquote(&pathInfo),1,'. ');
     %let pathTab = %qscan(%nrquote(&pathInfo),2,'. ');

	 %let freqInfo = %qscan(&inputTableList,2,' ');
     %let freqLib = %qscan(%nrquote(&freqInfo),1,'. ');
     %let freqTab = %qscan(%nrquote(&freqInfo),2,'. ');      
   %end;
   %else %do; %* all other code types ;
      %let inLib = %qscan(%nrquote(&inputtable),1,'. ');
      %let inTab = %qscan(%nrquote(&inputtable),2,'. ');
   %end;
  
   %let outLib = %qscan(%nrquote(&outputtable),1,'. ');
   %let outTab = %qscan(%nrquote(&outputtable),2,'. ');
  
   %* assume output libref engine determines if all are CAS ;
   proc sql noprint; 
     select upper(engine) into :outputEngine trimmed
     from dictionary.libnames where upcase(libname) eq %upcase("&outLib");
   quit;

   %* Assume not CAS ;
   %let isCAS=0;
   %if (&outputEngine ne CAS) %then %goto callService;
  
   %let isCAS=1;
   %* assume output CAS libref engine determines CAS session ;
   proc sql noprint;       
      select upper(sysvalue) into :outSession trimmed
      from dictionary.libnames
      where upcase(libname) eq %upcase("&outLib") and 
            upcase(sysname) eq "SESSION NAME";
   quit;
  
 %callService:
   %if &codeType eq DECISION_NODES_FREQ %then %do;
	  %if (&isCAS eq 1) %then %do;
	     proc cas;
		    session &outSession;
		    simple.freq result=r /
               casOut={caslib="&outLib",name="&outTab"}
               inputs={{name="PathID"}}
               table={caslib="&inLib",name="&inTab"};			
            run;
            table.alterTable /
               caslib="&outLib" name="&outTab"
               columns={{rename="PathID",name="_Charvar_"},
		 	            {rename="Count",name="_Frequency_"},
				        {drop=true,name="_Column_"},
					    {drop=true,name="_Fmtvar_"},
						{drop=true,name="_Level_"}};
            run;
         quit;
		 %goto promote;
	  %end;
	  %else %do;
	     proc freq data=&inputTable noprint;
             tables pathid / out=&outputTable(keep=PathID count);
	     run;
		 %goto exit;
	  %end;
   %end;
 
   %* Build the POST hints JSON.  Note that CARDS4 / DATALINES4 cannot be used inside a macro;
   filename postit temp;
   data _null_;
	  file postit;
	  
	  %if &codeType ne EXECUTION %then %do;
	    put '{ "analysisType": "' "&analysisCodeType" '",';
	  %end;
	  %else %do;  %* null mapping for EXECUTION ;
	    put '{ "termsMappings": [],';	  
	  %end;
	  
	  put '  "hints": {';
      put '     "outputLibraryName": "' "&outLib" '",';
	  put '     "outputTableName": "' "&outTab" '",';

	  %if &codeType eq EXECUTION %then %do;
	    put '     "isGeneratingRulefiredColumn": "' "TRUE" '",';
	    put '     "variableCarried": "' "FALSE" '",';
	    put '     "traversedPathFlag": "' "TRUE" '",';
	    put '     "lookupMode": "' "INLINE" '",';
	  %end;
  
	  %if &codeType eq DECISION_NODES_COUNTS %then %do;
	    put '     "decisionPathTableName": "' "&freqTab" '",';
	    put '     "decisionPathLibName": "' "&freqLib" '",';
	    put '     "decisionNodeTableName": "' "&pathTab" '",';
	    put '     "decisionNodeLibName": "' "&pathLib" '"';  
      %end;
      %else %do;
	    put '     "inputLibraryName": "' "&inLib" '",';
	    put '     "inputTableName": "' "&inTab" '"';
	  %end;  
	  put '  }';
	  put '}';
   run;
   
   %* Call REST service ;
   filename resp temp;
   %let _serviceCallRC = 0;
   %dcm_call_rest_service(
        service=&restEndpoint,
        method=POST,
        request=postit,
		response=resp,
		headers=%str("accept"="text/vnd.sas.source.ds2"
		             "content-type"=&contentType))     
 
   proc ds2
      %if (&isCAS eq 1) %then %do;
         sessref=&outSession
      %end;
      ;
      %inc resp;
   run; quit;

   %if (%sysfunc(fileref(resp)) LE 0) %then %do;
	  filename resp clear;
   %end;
	
%promote:	
   %if ((&isCAS eq 1) and (%upcase(&promote) eq YES)) %then %do;
	 proc cas;
	   session &outSession;
       table.promote / name="&outTab" caslib="&outLib" target="&outTab" targetLib="&outLib" ; run;
     quit;
   %end;
	
 %exit:
 %mend dcm_get_code;

 
******************************************************************************************;
*  Copyright (c) 2019 by SAS Institute, Inc., Cary, NC, USA.                             *;
*  All rights reserved.                                                                  *;
******************************************************************************************;
*  NAME:        dcm_decision_nodes_counts.sas                                            *;
*  DESCRIPTION: Generate and execute decision node count code                            *;
*  OWNER:       Carl Sommer - SAS Institute                                              *;
******************************************************************************************;
%macro dcm_decision_nodes_counts(
               URI=,            /* URI of the decision                                   */ 
               pathNodesTable=, /* libref.table produced by %DCM_DECISION_PATH_NODES     */
		       freqNodesTable=, /* libref.table produced by %DCM_DECISION_PATH_FREQUENCY */
		       outputTable=,    /* libref.table output table                             */
               promote=YES) ;  
   %dcm_get_code(URI=&uri
			   ,codeType=DECISION_NODES_COUNTS
			   ,inputTableList=%str(&pathNodesTable &freqNodesTable)
			   ,outputTable=&outputTable
			   ,promote=&promote) 
%mend dcm_decision_nodes_counts;

 
******************************************************************************************;
*  Copyright (c) 2018 by SAS Institute, Inc., Cary, NC, USA.                             *;
*  All rights reserved.                                                                  *;
******************************************************************************************;
*  NAME:        dcm_decision_path_frequency.sas                                          *;
*  DESCRIPTION: Generate and execute decision path frequency code                        *;
*  OWNER:       Carl Sommer - SAS Institute                                              *;
******************************************************************************************;
%macro dcm_decision_path_frequency(
                           URI=,            /* URI of the decision       */ 
                           inputTable=,     /* libref.table input table  */
		                   outputTable=,    /* libref.table output table */
                           promote=YES) ;    
   %dcm_get_code(URI=&uri
			   ,codeType=DECISION_NODES_FREQ
			   ,inputTable=&inputTable
			   ,outputTable=&outputTable
			   ,promote=&promote)
%mend dcm_decision_path_frequency;

 
******************************************************************************************;
*  Copyright (c) 2018 by SAS Institute, Inc., Cary, NC, USA.                             *;
*  All rights reserved.                                                                  *;
******************************************************************************************;
*  NAME:        dcm_decision_path_nodes.sas                                              *;
*  DESCRIPTION: Generate and execute decision path nodes code                            *;
*  OWNER:       Carl Sommer - SAS Institute                                              *;
******************************************************************************************;
%macro dcm_decision_path_nodes(
        URI=,            /* URI of the decision       */ 
        inputTable=,     /* libref.table input table  */
		outputTable=,    /* libref.table output table */
        promote=YES) ; 
   
   %dcm_get_code(URI=&uri
			   ,codeType=DECISION_PATH_NODES
			   ,inputTable=&inputTable
			   ,outputTable=&outputTable
			   ,promote=&promote)

%mend dcm_decision_path_nodes;

 
******************************************************************************************;
*  Copyright (c) 2018 by SAS Institute, Inc., Cary, NC, USA.                             *;
*  All rights reserved.                                                                  *;
******************************************************************************************;
*  NAME:        dcm_execute_decision.sas                                                 *;
*  DESCRIPTION: Generate and execute decision code                                       *;
*               Mapping is not supported.  Lookup mode is INLINE instead of FORMAT       *;
*  OWNER:       Carl Sommer                                                              *;
******************************************************************************************;
%macro dcm_execute_decision(
        URI=,            /* URI of the decision       */ 
        inputTable=,     /* libref.table input table  */
		outputTable=,    /* libref.table output table */
        promote=YES) ; 
   
   %dcm_get_code(uri=&URI
			   ,codeType=EXECUTION
			   ,inputTable=&inputTable
			   ,outputTable=&outputTable
			   ,promote=&promote)
%mend dcm_execute_decision;


******************************************************************************************;
*  Copyright (c) 2018 by SAS Institute, Inc., Cary, NC, USA.                             *;
*  All rights reserved.                                                                  *;
******************************************************************************************;
*  NAME:        dcm_execute_ruleset.sas                                                  *;
*  DESCRIPTION: Generate and execute ruleset code                                        *;
*               Mapping is not supported.  Lookup mode is INLINE instead of FORMAT       *;
*  OWNER:       Carl Sommer - SAS Institute                                              *;
******************************************************************************************;
%macro dcm_execute_ruleset(
        URI=,            /* URI of the ruleset        */ 
        inputTable=,     /* libref.table input table  */
		outputTable=,    /* libref.table output table */
        promote=YES) ; 

   %dcm_get_code(uri=&URI
			   ,codeType=EXECUTION
			   ,inputTable=&inputTable
			   ,outputTable=&outputTable
			   ,promote=&promote)
%mend dcm_execute_ruleset;


******************************************************************************************;
*  Copyright (c) 2018 by SAS Institute, Inc., Cary, NC, USA.                             *;
*  All rights reserved.                                                                  *;
******************************************************************************************;
*  NAME:        dcm_rulefire_detail.sas                                                  *;
*  DESCRIPTION: Generate and execute rulefired detail analysis code                      *;
*  OWNER:       Carl Sommer - SAS Institute                                              *;
******************************************************************************************;
%macro dcm_rulefire_detail(URI=,            /* URI of the decision or ruleset     */ 
                           inputTable=,     /* libref.table input table           */
		                   outputTable=,    /* libref.table output table          */
                           promote=YES) ;  
   
   %dcm_get_code(uri=&URI
			   ,codeType=RULEFIRE_DETAIL
			   ,inputTable=&inputTable
			   ,outputTable=&outputTable
			   ,promote=&promote) 
%mend dcm_rulefire_detail;


******************************************************************************************;
*  Copyright (c) 2018 by SAS Institute, Inc., Cary, NC, USA.                             *;
*  All rights reserved.                                                                  *;
******************************************************************************************;
*  NAME:        dcm_rulefire_summary.sas                                                 *;
*  DESCRIPTION: Generate and execute rulefired summary analysis code                     *;
*  OWNER:       Carl Sommer - SAS Institute                                              *;
******************************************************************************************;
%macro dcm_rulefire_summary(URI=,            /* URI of the decision or ruleset     */ 
                            inputTable=,     /* libref.table input table           */
		                    outputTable=,    /* libref.table output table          */
                            promote=YES) ;    
   %dcm_get_code(URI=&uri
			   ,codeType=RULEFIRE_SUMMARY
			   ,inputTable=&inputTable
			   ,outputTable=&outputTable
			   ,promote=&promote)
 %mend dcm_rulefire_summary;
 
 ******************************************************************************************;
*  Copyright (c) 2019 by SAS Institute, Inc., Cary, NC, USA.                             *;
*  All rights reserved.                                                                  *;
******************************************************************************************;
*  NAME:        dcm_get_revisions.sas                                                    *;
*  DESCRIPTION: Get the list of decisions or rulesets and related information into table *;
*               specified by the user.                                                   *;
*  OWNER:       Carl Sommer                                                              *;
******************************************************************************************;

%macro dcm_get_revisions(type=DECISION
                        ,name=_ALL_
                        ,table=work.revisions) ;

   %let type = %upcase(&type);       
   %if (&type eq DECISION) %then %let baseURI = %str(/decisions/flows);
   %else %if (&type eq RULESET) %then %let baseURI = %str(/businessRules/ruleSets);
      
   %* get the list of objects;
   filename resp temp;
  
   %if &name ne %str(_ALL_) %then %let daFilter= %nrstr(&)%str(filter=eq(name,"&name"));
   %else %let daFilter= %str();

   %dcm_call_rest_service(
        service=&baseURI.?start=0%nrstr(&)limit=10000%nrstr(&)&daFilter,
        method=GET,
        response=resp,
        headers=%str("accept"="application/vnd.sas.collection+json"
                     "content-type"="application/json"))     
 
   %* Build the map JSON.  Note that CARDS4 / DATALINES4 cannot be used inside a macro;		
   filename nameID temp;
   data _null_;
      file nameID;
      put '{"DATASETS": [';	  
	  put '{"DSNAME": "nameID","TABLEPATH": "/root/items","VARIABLES": [';
      put '{"NAME": "id", "TYPE": "CHARACTER", "PATH": "/root/items/id", "CURRENT_LENGTH": 36},';
	  put '{"NAME": "name", "TYPE": "CHARACTER", "PATH": "/root/items/name"}]}';	  
	  put ']}';
   run;
   libname resp json nrm noalldata automap=reuse map=nameID ordinalcount=none;
     
   %* Build the map JSON for a revision set. Note that CARDS4 / DATALINES4 cannot be used inside a macro; 
   filename revSet temp;
   data _null_;
      file revSet;
      put '{"DATASETS": [';	  
	  put '{"DSNAME": "revisions","TABLEPATH": "/root/items","VARIABLES": [';
      put '{"NAME": "creationTimeStamp", "TYPE": "NUMERIC","PATH": "/root/items/creationTimeStamp",';
	  put ' "INFORMAT" : [ "?IS8601DT", 19, 0 ], "FORMAT" : [ "IS8601DT", 19, 0 ]},';
      put '{"NAME": "modifiedTimeStamp", "TYPE": "NUMERIC", "PATH": "/root/items/modifiedTimeStamp",';
	  put ' "INFORMAT" : [ "?IS8601DT", 19, 0 ], "FORMAT" : [ "IS8601DT", 19, 0 ]},';
      put '{"NAME": "createdBy", "TYPE": "CHARACTER", "PATH": "/root/items/createdBy"},';
      put '{"NAME": "modifiedBy", "TYPE": "CHARACTER", "PATH": "/root/items/modifiedBy" },';
      put '{"NAME": "revisionId", "TYPE": "CHARACTER", "PATH": "/root/items/id", "CURRENT_LENGTH": 36},';
      put '{"NAME": "majorRevision", "TYPE": "NUMERIC", "PATH": "/root/items/majorRevision"},';
      put '{"NAME": "minorRevision", "TYPE": "NUMERIC", "PATH": "/root/items/minorRevision"}]}';      
	  put ']}';
   run;
      
   %macro dcm_getRevSet(name,baseID, revURI,counter);
     filename revResp temp;
     %* get a revision and put it to a temp enumerated table;
     %dcm_call_rest_service(
        service=&revUri?start=0%nrstr(&)limit=10000,
		method=GET,response=revResp,
        headers=%str("accept"="application/vnd.sas.collection+json"
                     "content-type"="application/json"))     

     libname revResp json nrm noalldata automap=reuse map=revSet ordinalcount=none;
     
	 data work._tempRev&counter;
	   length revisionURI $200;
       name = urldecode("&name");
       retain name;  retain baseId "&baseId";
	   set revResp.revisions;
	   revisionURI = catt("&revURI./",revisionid);
	 run; 	 
   %mend dcm_getRevSet;
   
   %let RevCount = 0;
   filename getRevs temp;
   data _null_;
      file getRevs;
      length revisionURI $100;
      set resp.nameID end=_last;
	  revisionURI = catt("&baseURI",'/',id,'/revisions');
      safeName = urlencode(strip(name));      
      put '%dcm_getRevSet(%nrstr(' safeName +(-1)'),%str(' id +(-1)'),%str(' revisionURI +(-1)'),' _n_ ')';
	  if _last then call symputx('RevCount',_n_);
   run;
   
   %if (&revCount eq 0) %then %goto exit;
 
   %inc getRevs;
      
   %* get all revisions for each ruleset/decision ;
   data &table;
     length revisionURI $200 name $256 baseId $36 creationTimeStamp modifiedTimeStamp 8 
        createdBy modifiedBy $32 revisionId $36 majorRevision minorRevision 8 type $15;
     retain type "&type";
     set work._tempRev: ;
   run;
   
   %exit:
    proc datasets lib=work memtype=data nolist noprint nowarn;
	   delete _tempRev:
    run; quit;
    
    %if %sysmacexist(dcm_getRevSet) %then %do; %sysmacdelete dcm_getRevSet /nowarn; %end;
	%if (%sysfunc(fileref(nameID))  le 0) %then %do; filename nameid  clear; %end; 
	%if (%sysfunc(fileref(revset))  le 0) %then %do; filename revset  clear; %end;
	%if (%sysfunc(fileref(resp))    le 0) %then %do; filename resp    clear; %end;
	%if (%sysfunc(fileref(getrevs)) le 0) %then %do; filename getrevs clear; %end;
	%if (%sysfunc(fileref(revresp)) le 0) %then %do; filename revresp clear; %end;  
    %if (%sysfunc(libref(resp))     eq 0) %then %do; libname  resp    clear; %end;
    %if (%sysfunc(libref(revresp))  eq 0) %then %do; libname  revresp clear; %end;

%mend dcm_get_revisions;
