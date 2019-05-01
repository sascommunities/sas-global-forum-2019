/* start cas server */
%let host=your_hostname_here;
%let port=your_port_here;
proc casoperate 
	host="&host" install="/path/to/install/loc" start=(term=yes) unxretry port=&port;
quit;
cas sascas1 host=("&host") port=&port uuidmac=sascas1_uuid;
libname sascas1 cas sessref=sascas1 datalimit=all;

%let nThreads=8;

/* path to query files */
%macro querydir(dir);
%let fpath=%sysget(SAS_EXECFILEPATH);
%let fname=%sysget(SAS_EXECFILENAME);
%let qpath=%sysfunc(tranwrd(&fpath,&fname,&dir));
%mend querydir;

%macro loadTableSynthetic(dir, nodescsv, linkscsv);
proc cas noqueue;
  	addcaslib  / caslib="synthetic_&graph" datasource={srctype="path"} path="&dir"; run;
	loadtable /    
		caslib="synthetic_&graph"    
  		path="&linkscsv"    
        singlepass=true
  		importoptions={filetype="csv", delimiter=',', nThreads=&nThreads}
        casout={name="LinkSetIn", replace=true}
	;
	loadtable /    
		caslib="synthetic_&graph"    
  		path="&nodescsv"    
        singlepass=true
  		importoptions={filetype="csv", delimiter=',', nThreads=&nThreads,
          vars={label={name="label", type="char", length=3}}}
        casout={name="NodeSetIn", replace=true}
		
	;
run;
quit;
%mend;


%macro patternMatch();
proc network
  nthreads=&nThreads
  loglevel=aggressive
  direction=undirected
  links=sascas1.LinkSetIn
  nodes=sascas1.NodeSetIn
  linksQuery=sascas1.linksQuery
  nodesQuery=sascas1.nodesQuery;
  nodesVar vars=(label);
  nodesQueryVar vars=(label);
  patternMatch;
run;
%put &_NETWORK_;
%mend patternMatch;


%macro readGraphQuery(which);
%inc "&qpath./&which..sas";
data sascas1.linksQuery; set links; run;
data sascas1.nodesQuery; set nodes; run;
%mend readGraphQuery;


%macro readAndSolve(which);
%readGraphQuery(&which);
%patternMatch();
%mend readAndSolve;


/* ba_u_10_15_200 */
%let graph=ba_u_10_15_200;
%let csvdir=/path/to/&graph./csv/data;
%let nodescsv=ba_200_nodes.csv;
%let linkscsv=ba_200_links.csv;

%querydir(&graph);
%loadTableSynthetic(&csvdir, &nodescsv, &linkscsv);

%readAndSolve(q01);
%readAndSolve(q02);
%readAndSolve(q03);
%readAndSolve(q04);
%readAndSolve(q05);


/* ba_u_10_15_400 */
%let graph=ba_u_10_15_400;
%let csvdir=/path/to/&graph./csv/data;
%let nodescsv=ba_400_nodes.csv;
%let linkscsv=ba_400_links.csv;

%querydir(&graph);
%loadTableSynthetic(&csvdir, &nodescsv, &linkscsv);

%readAndSolve(q01);
%readAndSolve(q02);
%readAndSolve(q03);
%readAndSolve(q04);
%readAndSolve(q05);
%readAndSolve(q06);


/* er_u_10_15_20 */
%let graph=er_u_10_15_20;
%let csvdir=/path/to/&graph./csv/data;
%let nodescsv=er_20_nodes.csv;
%let linkscsv=er_20_links.csv;

%querydir(&graph);
%loadTableSynthetic(&csvdir, &nodescsv, &linkscsv);

%readAndSolve(q01);
%readAndSolve(q02);


/* er_u_10_15_30 */
%let graph=er_u_10_15_30;
%let csvdir=/path/to/&graph./csv/data;
%let nodescsv=er_30_nodes.csv;
%let linkscsv=er_30_links.csv;

%querydir(&graph);
%loadTableSynthetic(&csvdir, &nodescsv, &linkscsv);

%readAndSolve(q01);
%readAndSolve(q02);
%readAndSolve(q03);


/* er_u_10_15_50 */
%let graph=er_u_10_15_50;
%let csvdir=/path/to/&graph./csv/data;
%let nodescsv=er_50_nodes.csv;
%let linkscsv=er_50_links.csv;

%querydir(&graph);
%loadTableSynthetic(&csvdir, &nodescsv, &linkscsv);

%readAndSolve(q01);
%readAndSolve(q02);
%readAndSolve(q03);


proc casoperate cashost="&host" casport=&port shutdown; quit;


