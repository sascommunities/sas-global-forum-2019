/*
Code 2977-2019
The Mother Of All Metadata Files: Using SAS® Provided
Macros To Manage Metadata
Hugh G. McCabe
Excellus Blue Cross Blue Shield
Full SAS Program including Excellus specific code:
*/

/* Hugh McCabe 06-22-2017: in the interest of full disclosure and attribution. I got all this metadata code from SAS Tech support. So, this is someone else's work and they should get credit! */
libname usermeta "/apps/sas/data/dmi/data/usermetadata";
libname authdata "/apps/sas/data/dmi/data/meta_auth_data";
libname tmp1day "/apps/sas/work/tmp1day";

/* this data null is just initializing a date value for use later in naming output files */
DATA _NULL_;
  TODAYX=compress(put("&sysdate9"D,yymmddN8.),'/');
  CALL SYMPUT ("TODAYX", COMPRESS(TODAYX));
RUN;

/***************** Start: library & permission data set up-staging. *****************/
/* Data set up-staging. This block gets library & permission data. */
/* This program queries the sas metadata (which is store as xml) and returns detailed */
/* data on our metadata libraries and their respective authorizations. so we can see */
/* we can see libraries and what groups have permissions on the libraries. */
/* The code is a sas macro from SAS Institute. b/c the data is stored in xml the */
/* queries are kind of hard to understand and if you spend too much time thinking */
/* about it your hair will hurt. HGM 20170628 */
/* sas indicated that this requires and elevated account */
/* and the example uses sasadm@saspw so as with any pw */
/* I encrypted it */
/*proc pwencode in=' ' method = sas003 ; run; */
/* connect to the metadata server */
options metaserver=saprdvmet.excellus.com metauser="username" metapass="{SAS003}XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";

/* run the main report macro against a target folder */
/* the folder option points to SAS Mgt Concole folder(s) */
/* I run 3 of these: /Divisional Folders, /Datamart and /Databases */
/* Heads up! the databases folder returns 30 million rows. it is */
/* row/col level & very detailed. I dump column level data so it is */
/* more manageable */
/* the mdsecds_join is the JACKPOT file */
/* here i am just dumping the data out to permanent sas data sets */
/* i am attaching a prefix to the data set name */
/* This is canned code from sas that queries the metadata */
/* to find this macro and documentation search %mdsecds */
/* http://support.sas.com/documentation/cdl/en/bisecag/63082/HTML/default/viewer.htm#n0l1mpdt430djgn1bl1c3euei85w.htm */
/**** Keys here are pointer to medtadata objects */
/* see screen shot of these objects from files tab from SMC */
%mdsecds(folder="/Datamart");

data authdata.datamart_mdsecds_join;
  set work.mdsecds_join;
run;

%mdsecds(folder="/Divisional Folders");

data authdata.DIVFLDR_mdsecds_join;
  set work.mdsecds_join;
run;

/* As mentioned this returns 30 MILLION rows */
/* so I am leaving it commented out until */
/* we feel that the oracle DB info need to be updated */
/*%mdsecds(folder="/Databases"); * updated 20181207 ; data authdata.DATABASES_mdsecds_join ; set work.mdsecds_join ; run; */
/* after the meta for each data type is extracted it needs */
/* needs to be combined into one data set. that happens next */
/* 20170706 hgm: I profiled this metadata figured out that in authorizations */
/* data, identityname is the SMC Group! Johnny was very helpful with this too. */
/* he suggested that i wasnt getting the correct rows */
/* and we should be able to join on objname from here (authdata) to the */
/* library data . may need to include identityname in the join. */
/* hang on to identitytype b/c it has "person"s SMC Groups */
data authdata.libraries_groups_perms;
  set authdata.DATABASES_MDSECDS_JOIN (in=databases) authdata.DATAMART_MDSECDS_JOIN (in=datamart) authdata.DIVFLDR_MDSECDS_JOIN (in=divfldr);
  length objecttype $ 20;

  * lots of metadata object types are returned. We thin it down here. */
  where PublicType in ("Folder", "Library" ) and metadatatype in ("SASLibrary" ) and identityname not in ("PUBLIC" , "SAS System Services" , "SASAdministrators" );
  if databases then
    objecttype = "Databases";
  if datamart then
    objecttype = "Datamart";
  if divfldr then
    objecttype = "Division Folder";
run ; /***************** End of library & permission data set up-staging. ***************/

/*************** Start: User SAS MetaData extract, set up-staging. ****************/
/* This is borrowed code. source: */
/*https://stackoverflow.com/questions/18950471/sas-script-to-list-all-sas-server-users-from-metadata */
data tmp1day.smc_users_grps;
  /* The LENGTH statement defines variables for function arguments and assigns the maximum length of each variable. */
  length uri uri2 uri3 uri4 name dispname group groupuri ExtLogin $256 id MDUpdate $20;

  /* The CALL MISSING routine initializes output variables to missing values. */
  n=1;
  n2=1;
  call missing(uri, uri2, uri3, uri4, name, dispname, group, groupuri, ExtLogin, id, MDUpdate);

  /* The METADATA_GETNOBJ function specifies to get the Person objects in the repository. The n argument specifies to get the first Person object that is returned. The uri argument will return the actual uri of the Person object that is returned. The program prints an informational message if no Person objects are found. */
  nobj=metadata_getnobj("omsobj:Person?@Id contains '.'",n,uri);
  if nobj=0 then
    put 'No Persons available.';

  /* The DO statement specifies a group of statements to be executed as a unit for the Person object that is returned by METADATA_GETNOBJ. The METADATA_GETATTR function gets the values of the object's Name and DisplayName attributes. */
  else
    do while (nobj > 0);
      objrc=metadata_getattr(uri, "Name", Name);
      objrc=metadata_getattr(uri, "DisplayName", DispName);

      /* The METADATA_GETNASN function gets objects associated via the InternalLoginInfo association. The InternalLoginInfo association returns internal logins. The n2 argument specifies to return the first associated object for that association name. The URI of the associated object is returned in the uri2 variable. */
      objrc=metadata_getnasn(uri,"InternalLoginInfo",n2,uri2);

      /* If a Person does not have any internal logins, set their IntLogin variable to 'No' Otherwise, set to 'Yes'. */
      IntLogin="Yes";
      DomainName="**None**";
      if objrc<=0 then
        do;
          put "NOTE: There are no internal Logins defined for " IdentName +(-1)".";
          IntLogin="No";
        end;

      /* The METADATA_GETNASN function gets objects associated via the Logins association. The Logins association returns external logins. The n2 argument specifies to return the first associated object for that association name. The URI of the associated object is returned in the uri3 variable. */
      objrc=metadata_getnasn(uri,"Logins",n2,uri3);

      /* If a Person does not have any logins, set their ExtLogin variable to '**None**' and output their name. */
      if objrc<=0 then
        do;
          put "NOTE: There are no external Logins defined for " IdentName +(-1)".";
          ExtLogin="**None**";
          output;
        end;

      /* If a Person has many logins, loop through the list and retrieve the name of each login. */
      do while(objrc>0);
        rc=metadata_getattr(uri3,"UserID",ExtLogin);

        /* If a Login is associated to an authentication domain, get the domain name. */
        DomainName="**None**";
        objrc2=metadata_getnasn(uri3,"Domain",1,uri4);
        if objrc2 >0 then
          do;
            objrc2=metadata_getattr(uri4,"Name",DomainName);
          end;

        /*Output the record. */
        output;
        n2+1;

        /* Retrieve the next Login's information */
        objrc=metadata_getnasn(uri,"Logins",n2,uri3); end; /*do while objrc*/

        /* The METADATA_GETNASN function gets objects associated via the IdentityGroups association. The a argument specifies to return the first associated object for that association type. The URI of the associated object is returned in the groupuri variable. */
        a=1;
        grpassn=metadata_getnasn(uri,"IdentityGroups",a,groupuri); /* If a person does not belong to any groups, set their group variable to 'No groups' and output their name. */
        if grpassn in (-3,-4) then
          do;
            group="No groups";
            output;
          end;

        /* If the person belongs to many groups, loop through the list and retrieve the Name and MetadataUpdated attributes of each group, outputting each on a separate record. */
        else
          do while (grpassn > 0);
            rc2=metadata_getattr(groupuri, "Name", group);
            rc=metadata_getattr(groupuri, "MetadataUpdated", MDUpdate);
            a+1;
            output;
            grpassn=metadata_getnasn(uri,"IdentityGroups",a,groupuri);
          end; /* Retrieve the next person's information */
        n+1;
        n2=1;
        nobj=metadata_getnobj("omsobj:Person?@Id contains '.'",n,uri);
      end;

      /* The KEEP statement specifies the variables to include in the output data set. */
      keep name dispname ExtLogin MDUpdate group;

      *** Thinning file to key fields ; 
run; 
/*************** End of User MetaData extract, set up-staging. *******************/

/**** Start of Code to find the physical location assoc with SMC Libraries ***/
/* this is some more borrowed code that queries the metadata ***/
/* This is pirated code */
/* https://communities.sas.com/t5/Administration-and-Deployment/Listing-Metadata-libraries/td-p/359558 */
data authdata.librarylocations;
  /* The LENGTH statement defines variables for function arguments and assigns the maximum length of each variable. */
  length liburi upasnuri $256 name $128 type id $17 libref engine $8 path mdschemaname schema $256;

  /* The KEEP statement defines the variables to include in the output data set. */
  keep name libref engine path mdschemaname schema;

  /* The CALL MISSING routine initializes the output variables to missing values. */
  call missing(liburi,upasnuri,name,engine,libref);

  /* The METADATA_GETNOBJ function specifies to get the SASLibrary objects in the repository. The argument nlibobj=1 specifies to get the first object that matches the requested URI. liburi is an output variable. It will store the URI of the returned SASLibrary object. */
  nlibobj=1;
  librc=metadata_getnobj("omsobj:SASLibrary?@Id contains '.'",nlibobj,liburi);

  /* The DO statement specifies a group of statements to be executed as a unit for each object that is returned by METADATA_GETNOBJ. The METADATA_GETATTR function is used to retrieve the values of the Name, Engine, and Libref attributes of the SASLibrary object. */
  do while (librc>0);
    /* Get Library attributes */
    rc=metadata_getattr(liburi,'Name',name); rc=metadata_getattr(liburi,'Engine',engine); rc=metadata_getattr(liburi,'Libref',libref); /* The METADATA_GETNASN function specifies to get objects associated to the library via the UsingPackages association. The n argument specifies to return the first associated object for that association type. upasnuri is an output variable. It will store the URI of the associated metadata object, if one is found. */
    n=1;
    uprc=metadata_getnasn(liburi,'UsingPackages',n,upasnuri);

    /* When a UsingPackages association is found, the METADATA_RESOLVE function is called to resolve the URI to an object on the metadata server. The CALL MISSING routine assigns missing values to output variables. */
    if uprc > 0 then
      do;
        call missing(type,id,path,mdschemaname,schema);
        rc=metadata_resolve(upasnuri,type,id);

        /* If type='Directory', the METADATA_GETATTR function is used to get its path and output the record */
        if type='Directory' then
          do;
            rc=metadata_getattr(upasnuri,'DirectoryName',path);
            output;
          end;

        /* If type='DatabaseSchema', the METADATA_GETATTR function is used to get the name and schema, and output the record */
        else if type='DatabaseSchema' then
          do;
            rc=metadata_getattr(upasnuri,'Name',mdschemaname);
            rc=metadata_getattr(upasnuri,'SchemaName',schema);
            output;
          end;

        /* Check to see if there are any more Directory objects */
        n+1;
        uprc=metadata_getnasn(liburi,'UsingPackages',n,upasnuri);
      end; /* if uprc > 0 */

    /* Look for another library */
    nlibobj+1;
    librc=metadata_getnobj("omsobj:SASLibrary?@Id contains '.'",nlibobj,liburi);
  end;

  /* do while (librc>0) */
run; 
/**** End ofCode to find the physical location assoc with SMC Libraries ***/