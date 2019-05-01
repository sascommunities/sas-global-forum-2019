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
%let qpath=&qpath/LUBM;

/* path to data graph */
%let csvdir=/path/to/lubm/csv/data;

/* node and link csv file names */
%let nodescsv=lubm_50_nodes.csv;
%let linkscsv=lubm_50_links.csv;


%macro loadTable(dir);
proc cas noqueue;
  	addcaslib  / caslib="lubm" datasource={srctype="path"} path="&csvdir"; run;
	loadtable /    
		caslib="lubm"    
  		path="&linkscsv"    
        singlepass=true
  		importoptions={filetype="csv", delimiter=',', nThreads=&nThreads}
        casout={name="LinkSetIn", replace=true}
	;
	loadtable /    
		caslib="lubm"    
  		path="&nodescsv"
        singlepass=true
  		importoptions={filetype="csv", delimiter=',', nThreads=&nThreads}
        casout={name="NodeSetIn", replace=true}
	;
run;
quit;
%mend;

%macro query(which);
%inc "&qpath/&which..sas";
%mend;

%loadTable;

%query(q02);
%query(q04);
%query(q05);
%query(q06);
%query(q07);
%query(q08_1);
%query(q08_2);
%query(q09);
%query(q12_1);
%query(q12_2);
%query(q12_3);
%query(q12_4);
%query(q13);
%query(q14);


proc casoperate cashost="&host" casport=&port shutdown; quit;
