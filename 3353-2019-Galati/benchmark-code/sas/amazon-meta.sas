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
%let fpath=%sysget(SAS_EXECFILEPATH);
%let fname=%sysget(SAS_EXECFILENAME);
%let qpath=%sysfunc(tranwrd(&fpath,&fname,));
%let qpath=&qpath/amazon-meta;

/* path to data graph */
%let csvdir=/path/to/amazon-meta/csv/data;

/* node and link csv file names */
%let nodescsv=amazon_nodes.csv;
%let linkscsv=amazon_links.csv;


%macro loadTableAmazon();
proc cas noqueue;
  	addcaslib  / caslib="amazon" datasource={srctype="path"} path="&csvdir"; run;
	loadtable /    
		caslib="amazon"    
  		path="&linkscsv"    
        singlepass=true
  		importoptions={filetype="csv", delimiter=',', nThreads=&nThreads}
        casout={name="LinkSetIn", replace=true}
	;
	loadtable /    
		caslib="amazon"    
  		path="&nodescsv"    
        singlepass=true
  		importoptions={filetype="csv", delimiter=',', nThreads=&nThreads}
        casout={name="NodeSetIn", replace=true}
	;
run;
quit;
%mend;


%macro readGraphQueryAmazon(which);
%inc "&qpath./&which..sas";
data sascas1.linksQuery; set links; run;
data sascas1.nodesQuery; set nodes; run;
%mend readGraphQueryAmazon;


%macro patternMatchAmazon();
proc network
  nthreads=&nThreads
  multiLinks=true
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
%mend patternMatchAmazon;

%macro readAndSolveAmazon(dir);
%readGraphQueryAmazon(&dir);
%patternMatchAmazon();
%mend readAndSolveAmazon;

%loadTableAmazon();
%readAndSolveAmazon(q01);
%readAndSolveAmazon(q02);
%readAndSolveAmazon(q03);


proc casoperate cashost="&host" casport=&port shutdown; quit;



