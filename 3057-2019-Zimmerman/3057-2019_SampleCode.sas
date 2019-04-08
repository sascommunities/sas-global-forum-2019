/*----------------------------------------------------------------*/
/*       Sample Code associated with Paper SAS3057-2019           */
/*       SAS® Functions to Drive Source Control With Git           */
/*  	  Danny Zimmerman, SAS Institute Inc. Cary, NC            */
/*                                                                */
/*----------------------------------------------------------------*/




/*----------------------------------------------------------------*/
/*                                                                */
/*   Interacting with the Remote Repository function examples     */
/*                                                                */
/*----------------------------------------------------------------*/

/*Clone example*/

data work.clone;
RC = GITFN_CLONE("<Remote Repository URL>",
				 "<Location to clone repository to>", 
				 "<User Name>", 
				 "<Password>", /* Accepts SASEncoded passwords encoded using "PROC PWENCODE" */
				 "<Path to public ssh key if using an ssh URL>",
				 "<Path to private ssh key if using an ssh URL>");
run;
/*END Clone Example */

/* Push Example */
/*ssh version */
data work.push;
rc = GITFN_PUSH("<Local Repository Path>", 
				  "git", /* When using SSH the username needs to be whatever comes before the @ in the URL. */
						 /* For example: git@github.com:sasdazimm/sasgit.git */
				  "",
				  "<Path to public SSH key>",
				  "<Path to private SSH key>"); 
run;
	
/*https version */
data work.push;
push = GITFN_PUSH("<Local Repository Path>", "<User Name>", "<Password>");
run;

/*END Push Example */


/* Pull Example using SSH keys */
data work.pull;
pull = GITFN_PULL("<Local Repository Path>", "git", "", 
				  "<Path to public SSH key>", 
				  "<Path to private SSH key>");
run;		

/*END Pull Example */





/*----------------------------------------------------------------*/
/*                                                                */
/*       Stage, Unstage and Commit function examples              */
/*                                                                */
/*----------------------------------------------------------------*/

/* Add To index (stage) example. Can stage 1 to N number of files. */
data work.add;
RC = GITFN_IDX_ADD("<Local Repository Path>", 
				   "<File Path relative to the local repository path>", 
				   "<File Status>" /* File Status must be one of the following: modified, deleted, new */
				   ); 
run;

/*END Add to index example */

/* Remove from index (unstage) example. Can unstage 1 to N number of files. */
data work.remove;
RC = GITFN_IDX_REMOVE("<Local Repository Path>", "<File Path relative to the local repository path>");
run;

/* END Remove from Index Example */

/* Commit Example */
data work.commit;
commit = GITFN_COMMIT("<Local Repository Path>",
                      "HEAD", /* Update Reference Name "HEAD" commits to the head of the current branch */
                      "<Author Name>", 
                      "<Author Email>", 
                      "<Commit Message>"); 
run;

/*END Commit Example */




/*----------------------------------------------------------------*/
/*                                                                */
/*       Status, Repo History, and Diffs function examples        */
/*                                                                */
/*----------------------------------------------------------------*/

/* Local Repo Status Example */
DATA work.status;

    /*---------------------------------------------------------------*/
    /* Make sure you allocate lengths and initialize.                */
    /*---------------------------------------------------------------*/
    
    LENGTH PATH $ 1024;
    LENGTH STATUS $ 64;
    LENGTH STAGED $ 32;
    PATH="";
    STATUS="";
    STAGED="Staged";
    N=1;
    
    /*---------------------------------------------------------------------*/
    /* Get the number of objects that have changed in the local repository */
    /*---------------------------------------------------------------------*/
    N=GITFN_STATUS("<Local Repository Path>");
    /*----------------------------------------------------------------*/
    /* N returns the number of objects have changed, or -1.           */
    /*                                                                */
    /* Now, iterate through the status objects. From the SAS side     */
    /* you'll be using a numeric index.                               */
    /*----------------------------------------------------------------*/
    
    DO I=1 TO N;
        
        RC=GITFN_STATUS_GET(I,"<Local Repository Path>", "Path",Path);
        RC=GITFN_STATUS_GET(I,"<Local Repository Path>", "Status",Status);
        RC=GITFN_STATUS_GET(I,"<Local Repository Path>", "Staged",Staged);
        PUT PATH=;
        PUT STATUS=;
        PUT STAGED=;
        output;
    END;
    
    /*----------------------------------------------------------------*/
    /* There is no garbage collection in SAS so free your objects.    */
    /* Index by local repository path.                                */
    /*----------------------------------------------------------------*/
    RC=GITFN_STATUSFREE("<Local Repository Path>");

RUN;

/* Commit Log Example */
data work.commitlog;
	N=1;
	LENGTH COMMIT_ID $ 50;
	LENGTH AUTHOR_NAME $ 1024;
	LENGTH AUTHOR_EMAIL $ 1024;
	LENGTH MESSAGE $ 1024;
	LENGTH PARENT_IDS $ 1024;
	LENGTH TIME $ 20;

	COMMIT_ID="";
	AUTHOR_NAME="";
	AUTHOR_EMAIL="";
	MESSAGE="";
	PARENT_IDS="";
	TIME="";

	N = GITFN_COMMIT_LOG("<Local Repository Path>");
	PUT N=;
	DO I=1 TO N;
		RC = GITFN_COMMIT_GET(I,"<Local Repository Path>", "id", COMMIT_ID);
		RC = GITFN_COMMIT_GET(I,"<Local Repository Path>", "author", AUTHOR_NAME);
		RC = GITFN_COMMIT_GET(I,"<Local Repository Path>", "email", AUTHOR_EMAIL);
		RC = GITFN_COMMIT_GET(I,"<Local Repository Path>", "message", MESSAGE);
		RC = GITFN_COMMIT_GET(I,"<Local Repository Path>", "parent_ids", PARENT_IDS);
		RC = GITFN_COMMIT_GET(I,"<Local Repository Path>", "time", TIME); 
		PUT COMMIT_ID=;
		PUT AUTHOR_NAME=;
		PUT AUTHOR_EMAIL=;
		PUT MESSAGE=;
		PUT PARENT_IDS=;
		PUT TIME=; 
		output; 
	END;
	RC = GITFN_COMMITFREE("<Local Repository Path>");
run;
proc print data=work.commitlog; run;
/*END Commit Log Example */



/* Diff Example */
data work.diff;
	LENGTH FILE_PATH $ 1024;
	LENGTH DIFF_CONTENT $ 32767;
	LENGTH DIFF_TYPE $ 1024;
	FILE_PATH="";
	DIFF_CONTENT="";
	DIFF_TYPE="";
	N = GITFN_DIFF("<Local Repository Path>", "<Commit ID of older commit>", "<Commit ID of more recent commit>");
	PUT N=;
	DO I=1 TO N;
		RC = GITFN_DIFF_GET(I,"<Local Repository Path>", "<Commit ID of older commit>", "<Commit ID of more recent commit>", "file", FILE_PATH);
		RC = GITFN_DIFF_GET(I,"<Local Repository Path>", "<Commit ID of older commit>", "<Commit ID of more recent commit>", "diff_content", DIFF_CONTENT);
		RC = GITFN_DIFF_GET(I,"<Local Repository Path>", "<Commit ID of older commit>", "<Commit ID of more recent commit>", "diff_type", DIFF_TYPE);
		PUT FILE_PATH=;
		PUT DIFF_CONTENT=;
		PUT DIFF_TYPE=;
		output;
	END;
	RC = GITFN_DIFF_FREE("<Local Repository Path>", "<Commit ID of older commit>", "<Commit ID of more recent commit>");

run;
proc print data=work.diff; 
run;
/*END Diff Example */





/*----------------------------------------------------------------*/
/*                                                                */
/*             Branching function examples                        */
/*                                                                */
/*----------------------------------------------------------------*/

data work.branch;
branch = GITFN_NEW_BRANCH("<Local Repository Path>", 
						  "<Commit ID of the commit to create new branch>", 
						  "<Branch Name>", 
						  nForce /* nForce (optional) 1: to force the creation of the branch if the branch name already exists. */
						  ); 
run;

data _null_;
rc = GITFN_DEL_BRANCH("<Local Repository Path>", "<Branch Name>");
run;

data _null_;
rc = GITFN_CO_BRANCH("<Local Repository Path>", "<Branch Name>");
run;

data _null_;
rc = GITFN_MRG_BRANCH("<Local Repository Path>", "<Branch name to merge into current branch>", "<User Name>", //User name puts a name on the merge commits (Informational)
																							   "<User Email>" //User email is also for merge commits
					 );
run;





/*----------------------------------------------------------------*/
/*                                                                */
/*                 Utility function examples                      */
/*                                                                */
/*----------------------------------------------------------------*/

/*Deletes local repository and all of its content.*/
data work.delete;
RC = GITFN_DEL_REPO("<Local Repository Path>");
run;


/* Reset local repository to a specific commit */
data work.reset;
reset = GITFN_RESET("<Local Repository Path>", "<Commit ID to reset to>", "<Reset Type>"); /* Reset Type Options: HARD (Reset working directory and index), 
																												  MIXED (leave working directoy untouched, reset index),
																												  SOFT  (leave working directory and index untouched)*/
run;

/*Reset a file in the staging area */
data _null_;
rc = GITFN_RESET_FILE("<Local Repository Path>", "<File Path relative to local repository>");
run;
/*END Reset Example */ 

/* Diff a file in the staging area to the last commit */
data _null_;
LENGTH DIFF_CONTENT $ 32767;
DIFF_CONTENT="";
rc=GITFN_DIFF_IDX_F("<Local Repository Path>", "<File Path relative to local repository>", DIFF_CONTENT);
PUT DIFF_CONTENT=;
output;
run;

/*Version function -- returns the version of the libgit2 library.*/
data work.version;
RC = GITFN_VERSION();
put RC=;
output;
run;
proc print data=work.version; run;

