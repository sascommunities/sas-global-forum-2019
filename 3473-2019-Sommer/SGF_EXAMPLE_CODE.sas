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
