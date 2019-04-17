/***************************************/
/* SAS Global Forum 2019               */
/* Data Quality Programming Techniques */
/* with SAS Cloud Analytic Services    */
/* Paper SAS3030-2019                  */
/* Nicolas Robert (SAS)                */
/***************************************/

/* Provide more messages in the log */
options msglevel=i ;

/* Create a CAS session */
cas mySession sessopts=(messagelevel=all metrics=true) ;

/* Create a CASLIB */
caslib mydata datasource=(srctype=path) path="/gelcontent/demo/DM/data/SAMPLE" ;

/* Assign a CAS engine library */
libname mylib cas caslib="mydata" ;
 
/* Load the customers table from the DM caslib to the new dataproc caslib */
proc casutil ;
   load casdata="customersSGF.sas7bdat" incaslib="mydata" outcaslib="mydata" casout="mycustomers" copies=0 replace ;
quit ;

/* Profile data using the profile CAS action */
proc cas ; 
   dataDiscovery.profile /
      algorithm="PRIMARY"
      table={caslib="mydata" name="mycustomers"}
      columns={"id","name","address","city","state","zip","updatedate"}
      cutoff=20
      frequencies=10
      outliers=5
      casOut={caslib="mydata" name="mycustomers_profiled" replace=true replication=0} ;
quit ;

/* Profile data and Identity analysis using the profile CAS action */
proc cas ; 
   dataDiscovery.profile /
      algorithm="PRIMARY"
      table={caslib="mydata" name="mycustomers"}
      multiIdentity=true
      locale="ENUSA"
      qkb="QKB CI 29"
      identities= {
         {pattern=".*", type="*", definition="Field Content", prefix="QKB_"}
      }
      cutoff=20
      frequencies=10
      outliers=5
      casOut={caslib="mydata" name="mycustomers_profiled" replace=true replication=0} ;
quit ;

/* Fetch the output table in the Results and observe metric #1028 */
proc cas ;
   table.fetch /
       table={
         caslib="mydata" name="mycustomers_profiled"} to=200 ;
quit ;

/* Short use case to understand multiIdentity */
data mylib.sample ;
   length var $ 20 ;
   var="New York" ; output ; 
   var="Washington" ; output ; 
   var="California" ; output ;
run ;

/* multiIdentity=true */
/* observe metric #1028 */
proc cas; 
   dataDiscovery.profile /
      algorithm="PRIMARY"
      table={caslib="mydata" name="sample"}
      columns={"var"}
      multiIdentity=true
      locale="ENUSA"
      qkb="QKB CI 29"
      identities= {
         {pattern=".*", type="*", definition="Field Content", prefix="QKB_"}
      }
      cutoff=20
      frequencies=10
      outliers=5
      casOut={caslib="mydata" name="sample_profiled" replace=true replication=0} ;
   table.fetch /
       table={
         caslib="mydata" name="sample_profiled"} to=200 ;
quit ;

/* multiIdentity=false */
/* observe metric #1028 */
proc cas; 
   dataDiscovery.profile /
      algorithm="PRIMARY"
      table={caslib="mydata" name="sample"}
      columns={"var"}
      multiIdentity=false
      locale="ENUSA"
      qkb="QKB CI 29"
      identities= {
         {pattern=".*", type="*", definition="Field Content", prefix="QKB_"}
      }
      cutoff=20
      frequencies=10
      outliers=5
      casOut={caslib="mydata" name="sample_profiled" replace=true replication=0}
   ;
   table.fetch /
       table={
         caslib="mydata" name="sample_profiled"} to=200 ;
quit ;

/* Transform, cleanse data using DQ data step functions */
data mylib.mycustomers_dq ;
   length gender $1 mcName mcAddress parsedValue
          tokenNames lastName firstName stateStd varchar(100) ;
   set mylib.mycustomers ;
   gender=dqGender(name,'Name','ENUSA') ;
   mcName=dqMatch(name,'Name',95,'ENUSA') ; 
   mcAddress=dqMatch(address,'Address (Street Only)',95,'ENUSA') ;
   parsedValue=dqParse(name,'Name','ENUSA') ;
   tokenNames=dqParseInfoGet('Name','ENUSA') ;
   if _n_=1 then put tokenNames= ;
   lastName=dqParseTokenGet(parsedValue,'Family Name','Name','ENUSA') ;
   firstName=dqParseTokenGet(parsedValue,'Given Name','Name','ENUSA') ;
   stateStd=dqStandardize(state,'State/Province (Abbreviation)','ENUSA') ;
run ;

/* Cluster records with fuzzy and exact matching rules */
proc cas ;
   entityRes.match /
      clusterId="clusterID"
      inTable={caslib="mydata",name="mycustomers_dq"}
      columns={"id","firstName","lastName","gender","address","city","zip","stateStd","updateDate","mcName","mcAddress"}
      matchRules={{
         rule={{
            columns={"mcName","mcAddress","stateStd"}
         }}
      }}
      nullValuesMatch=false
      emptyStringIsNull=true
      outTable={caslib="mydata",name="mycustomers_clustered",replace=true} ;
quit ;

/* Output only multi-rows clusters */
data mylib.mycustomers_clustered_dups ;
   set mylib.mycustomers_clustered ;
   by clusterId ;
   if first.clusterId and last.clusterId then delete ;
run ;

/* De-duplicate records using data step and a basic rule (most recent record) */
data mylib.mycustomers_dedup ;
   set mylib.mycustomers_clustered ;
   by clusterID updateDate ;
   if last.clusterID then output ;
run ;

/* De-duplicate using the groubyinfo CAS action and a basic rule (first record) */
proc cas ;
   simple.groupByInfo /
      table={caslib="mydata",name="mycustomers_clustered",groupBy={"clusterID"}}
      copyVars={"id","firstName","lastName","gender","address","city","zip","stateStd","updateDate"}
      casOut={caslib="mydata",name="mycustomers_dedup",replace=true}
      position=1
      generatedColumns={"FREQUENCY","GROUPID","POSITION"}
      details=true ;
quit ;

/* sample code to de-duplicate records using advanced rules */
/* This example is incomplete, all the fields are not populated */
data mylib.mycustomers_dedup ;
   length new_id 8 new_firstName new_lastName varchar(36) new_gender $ 1 
          new_address varchar(92) new_city varchar(72) new_zip $ 10 new_state $ 2 ;
   retain max_date new_id new_zip ;
   set mylib.mycustomers_clustered ;
   by clusterID ;
   /* initialization */
   if first.clusterID then do ;
      max_date=updateDate ;
      new_id=id ;
      new_zip=zip ;
   end ;
   /* rule 1: get the customer id of the most recently updated record */
   if updateDate>max_date then do ;
      max_date=updateDate ;
      new_id=id ;
   end ;
   /* rule 2: get a ZIP+4 when available */
   if dqPattern(zip,'CHARACTER','ENUSA')="99999*9999" then do ;
      new_zip=zip ;
   end ;
   /* output the "golden" record when the last cluster record is read */
   if last.clusterId then output ;
run ;

/* Terminate the CAS session */
cas mysession terminate ;
