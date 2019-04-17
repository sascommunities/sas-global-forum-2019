OPTIONS COMPRESS=BINARY ERRORS=0 DQUOTE REUSE=YES;

*** Test with 2nd data set ***;
%LET ds=input file;
%LET outds=output file;

LIBNAME LG input directory;
LIBNAME OUT output directory;

*** Check the source data set as a baseline ***;
PROC CONTENTS DATA=lg.&ds OUT=start_contents;
RUN;

QUIT;

*** Initialize the tracker for the sizes and diagnostics ***;
%LET stat=0;
%LET diag=0;

*** Update the tracker for the sizes ***;
%LET stat=%EVAL(&stat+1);

*** Save the size of the data set ***;
DATA _NULL_;
	SET sashelp.vtable(WHERE=(libname='LG' AND memname="&ds" AND typemem='DATA'));
	CALL SYMPUT("label&stat","Initial size");
	CALL SYMPUT("figure&stat",filesize);
RUN;
QUIT;

%PUT &stat &&label&stat &&figure&stat;

*** Create a local copy for the program - it uses the OPTIONS in the OPTIONS statement ***;
DATA X;
	SET LG.&ds;
RUN;

QUIT;

*** Check space and metadata ***;
PROC CONTENTS DATA=x OUT=x_contents;
RUN;

QUIT;

*** Update the tracker for the sizes ***;
%LET stat=%EVAL(&stat+1);

*** Save the size of the data set ***;
DATA _NULL_;
	SET sashelp.vtable(WHERE=(libname='WORK' AND memname='X' AND typemem='DATA'));
	CALL SYMPUT("label&stat","After COMPRESS=BINARY");
	CALL SYMPUT("figure&stat",filesize);
RUN;

QUIT;

%PUT &stat &&label&stat &&figure&stat;

*** Get count of character and numeric variables ***;
PROC FREQ DATA=x_contents;
	TABLES type;
RUN;

QUIT;

*** Split data into numeric and character variables ***;
DATA numeric(KEEP=_NUMERIC_)  character(KEEP=_CHARACTER_);
	SET x;
RUN;

QUIT;

*** Check space and metadata ***;
PROC CONTENTS DATA=numeric OUT=numeric_contents;
RUN;

QUIT;

*** Update the tracker for the sizes ***;
%LET stat=%EVAL(&stat+1);

*** Save the size of the data set ***;
DATA _NULL_;
	SET sashelp.vtable(WHERE=(libname='WORK' AND memname='NUMERIC' AND typemem='DATA'));
	CALL SYMPUT("label&stat","Numeric");
	CALL SYMPUT("figure&stat",filesize);
RUN;

QUIT;

%PUT &stat &&label&stat &&figure&stat;

PROC CONTENTS DATA=character OUT=character_contents;
RUN;

QUIT;

*** Update the tracker for the sizes ***;
%LET stat=%EVAL(&stat+1);

*** Save the size of the data set ***;
DATA _NULL_;
	SET sashelp.vtable(WHERE=(libname='WORK' AND memname='CHARACTER' AND typemem='DATA'));
	CALL SYMPUT("label&stat","Character");
	CALL SYMPUT("figure&stat",filesize);
RUN;

QUIT;

%PUT &stat &&label&stat &&figure&stat;
OPTIONS MPRINT;

*** Set up macro variables for numeric variables ***;
DATA _NULL_;
	SET numeric_contents END=eof;
	RETAIN count 0;

	** Use suffix of n so that non-alphnumeric characters can be used ***;
	count+1;
	CALL SYMPUT('NV'||LEFT(PUT(COUNT,4.)),'"'||TRIM(name)||'"n');

	** Variable name ***;
	CALL SYMPUT('NI'||LEFT(PUT(COUNT,4.)),'0');

	** Is it an integer? ***;
	CALL SYMPUT('NSFX'||LEFT(PUT(COUNT,4.)),'"_'||TRIM(SUBSTR(name,2))||'"n');

	*** For later rename ***;
	IF eof THEN
		DO;
			CALL SYMPUT('NCOUNT',LEFT(PUT(count,4.)));

			*** Count of numeric variables ***;
		END;
RUN;

QUIT;

%PUT &ncount;

*** Determine which values are integers ***;
***  Only integers can have their length changed without losing accuracy  ***;
%MACRO GETINT;

	DATA integer_x;
		LENGTH 
			%DO I=1 %TO &ncount;
		ni&i
		%END;
		3;
		SET numeric;

		%DO I=1 %TO &ncount;
			IF &&nv&i=INT(&&nv&i) THEN
				ni&i=1;
			ELSE ni&i=0;
		%END;
	RUN;

	QUIT;

%MEND GETINT;

%GETINT;

%MACRO GETINT2;
	*** Get maximum and minimum values for each numeric variable ***;
	PROC SUMMARY MIN MAX DATA=integer_x NWAY MISSING;
		VAR 
			%DO I=1 %TO &ncount;
		&&nv&i
		%END;
		;
		OUTPUT OUT=integer_counts(DROP=_TYPE_ _FREQ_) 
			MIN=
			%DO I=1 %TO &ncount;
		integer_min&i
		%END;

		MAX=

			%DO I=1 %TO &ncount;
				integer_max&i
			%END;
		;
	RUN;

	QUIT;

	*** If the integer check has a miminimum of 1, all values of the variable are integers or missing **;
	PROC SUMMARY MIN MAX DATA=integer_x NWAY MISSING;
		VAR 
			%DO I=1 %TO &ncount;
		ni&i
		%END;
		;
		OUTPUT OUT=integer_counts2(DROP=_TYPE_ _FREQ_) 
			MIN=
			%DO I=1 %TO &ncount;
		int_check_min&i
		%END;

		MAX=

			%DO I=1 %TO &ncount;
				int_check_max&i
			%END;
		;
	RUN;

	QUIT;

%MEND GETINT2;

%GETINT2;

*** Combine the minimum and maximum values for the variables and the integer checks ***;
*** Create macro variables of the maximum and minimum values ***;
DATA integer_counts_all;
	MERGE integer_counts integer_counts2;
	ARRAY int_check_min int_check_min1-int_check_min&ncount;
	ARRAY int_check_max int_check_max1-int_check_max&ncount;
	ARRAY integer_min integer_min1-integer_min&ncount;
	ARRAY integer_max integer_max1-integer_max&ncount;

	DO I=1 TO &ncount;
		CALL SYMPUT('int_check_min'||LEFT(PUT(i,4.)),int_check_min{i});
		CALL SYMPUT('int_check_max'||LEFT(PUT(i,4.)),int_check_max{i});
		CALL SYMPUT('integer_min'||LEFT(PUT(i,4.)),integer_min{i});
		CALL SYMPUT('integer_max'||LEFT(PUT(i,4.)),integer_max{i});
	END;

	DROP i;
RUN;

QUIT;

*** Reclaim space ***;
PROC DELETE DATA=integer_x;
RUN;

QUIT;

*** Take the integer variables and shrink their length as much as possible ***;
***  The cutoff points listed below are in support.sas.com ***;
***    The default length of numeric variables is  8 ***;
%MACRO GETINT3;

	DATA revised_numeric;
		LENGTH 
			%DO I=1 %TO &ncount;

		%IF &&int_check_min&i=1 %THEN
			%DO;
				%IF %SYSFUNC(MAX(%SYSFUNC(ABS(&&integer_min&i)),%SYSFUNC(ABS(&&integer_max&i))))<8192 %THEN
					%DO;
						&&nv&i 3.
					%END;
				%ELSE %IF %SYSFUNC(MAX(%SYSFUNC(ABS(&&integer_min&i)),%SYSFUNC(ABS(&&integer_max&i))))<2097152 %THEN
					%DO;
						&&nv&i 4.
					%END;
				%ELSE %IF %SYSFUNC(MAX(%SYSFUNC(ABS(&&integer_min&i)),%SYSFUNC(ABS(&&integer_max&i))))<536870912 %THEN
					%DO;
						&&nv&i 5.
					%END;
				%ELSE %IF %SYSFUNC(MAX(%SYSFUNC(ABS(&&integer_min&i)),%SYSFUNC(ABS(&&integer_max&i))))<137438953472 %THEN
					%DO;
						&&nv&i 6.
					%END;
				%ELSE %IF %SYSFUNC(MAX(%SYSFUNC(ABS(&&integer_min&i)),%SYSFUNC(ABS(&&integer_max&i))))<35184372088832 %THEN
					%DO;
						&&nv&i 7.
					%END;
			%END;
%END;
		;
		SET numeric;
	RUN;

	QUIT;

%MEND GETINT3;

%GETINT3;

*** Check the space and the metadata to compare the results ***;
PROC CONTENTS DATA=revised_numeric OUT=revised_numeric_contents;
RUN;

QUIT;

*** Make sure the values have not changed ***;
PROC COMPARE BASE=numeric COMPARE=revised_numeric OUT=numeric_comparison;
RUN;

QUIT;

PROC COMPARE BASE=numeric COMPARE=revised_numeric OUT=numeric_comparison_outnoequal OUTNOEQUAL;
RUN;

QUIT;

** Set the output variable for mismatches ***;
%LET diag=%EVAL(&diag+1);

DATA _NULL_;
	CALL SYMPUT("diaglbl&diag","After Numeric Compare");
	CALL SYMPUT("diagamt&diag",missobs&diag);
	STOP;
	SET numeric_comparison_outnoequal NOBS=missobs&diag;
RUN;

QUIT;

%PUT &diag &&diaglbl&diag &&diagamt&diag;

*** Save space ***;
PROC DELETE DATA=numeric;
RUN;

QUIT;

*** Update the tracker for the sizes ***;
%LET stat=%EVAL(&stat+1);

*** Save the size of the data set ***;
DATA _NULL_;
	SET sashelp.vtable(WHERE=(libname='WORK' AND memname='REVISED_NUMERIC' AND typemem='DATA'));
	CALL SYMPUT("label&stat","Revised Numeric");
	CALL SYMPUT("figure&stat",filesize);
RUN;

QUIT;

%PUT &stat &&label&stat &&figure&stat;

*** Set up macro variables for character variables***;
DATA _NULL_;
	SET character_contents END=eof;
	RETAIN count 0;
	count+1;
	CALL SYMPUT('CV'||LEFT(PUT(COUNT,4.)),name);

	*** Variable name ***;
	CALL SYMPUT('CL'||LEFT(PUT(COUNT,4.)),length);

	*** Variable length ***;
	CALL SYMPUT('CSFX'||LEFT(PUT(COUNT,4.)),'_'||SUBSTR(name,2));

	*** For later rename ***;
	IF eof THEN
		DO;
			CALL SYMPUT('CCOUNT',LEFT(PUT(count,4.)));

			*** Count of character variables ***;
		END;
RUN;

QUIT;

%PUT &ccount;

*** Get the actual length of each character variable ***;
%MACRO GETCHAR;

	DATA character2;
		SET character;

		%DO I=1 %TO &ccount;
			obs_length&i=LENGTH(&&cv&i);
		%END;
	RUN;

	QUIT;

%MEND GETCHAR;

%GETCHAR;

*** Get the maximum length for each character variable ***;
PROC SUMMARY MISSING MAX NWAY DATA=character2;
	VAR obs_length1-obs_length&ccount;
	OUTPUT OUT=character_max(DROP=_TYPE_ _FREQ_) MAX=obs_max1-obs_max&ccount;
RUN;

QUIT;

*** Put the maximum length into macro variables ***;
DATA _NULL_;
	SET character_max;
	ARRAY obs_max obs_max1-obs_max&ccount;

	DO I=1 TO &ccount;
		CALL SYMPUT('obs_max'||LEFT(PUT(i,4.)),obs_max{i});
	END;
RUN;

QUIT;

*** Shrink the length to what is required for each variable in the data set ***;
%MACRO GETCHAR2;

	DATA revised_character;
		LENGTH
			%DO I=1 %TO &ccount;

		%IF &&obs_max&i<&&cl&i %THEN
			%DO;
				&&cv&i $&&obs_max&i
			%END;
%END;
		;
		SET character2 (DROP=obs_length1-obs_length&ccount);
	RUN;

	QUIT;

%MEND GETCHAR2;

%GETCHAR2;

*** Check the space and metadata to compare the results  ***;
PROC CONTENTS DATA=revised_character OUT=revised_character_contents;
RUN;

QUIT;

*** Make sure the values have not changed ***;
PROC COMPARE BASE=character COMPARE=revised_character OUT=character_comparison;
RUN;

QUIT;

PROC COMPARE BASE=character COMPARE=revised_character OUT=character_comparison_outnoequal OUTNOEQUAL;
RUN;

QUIT;

** Set the output variable for mismatches ***;
%LET diag=%EVAL(&diag+1);

DATA _NULL_;
	CALL SYMPUT("diaglbl&diag","After Character Compare");
	CALL SYMPUT("diagamt&diag",missobs&diag);
	STOP;
	SET character_comparison_outnoequal NOBS=missobs&diag;
RUN;

QUIT;

%PUT &diag &&diaglbl&diag &&diagamt&diag;

*** Update the tracker for the sizes ***;
%LET stat=%EVAL(&stat+1);

*** Save the size of the data set ***;
DATA _NULL_;
	SET sashelp.vtable(WHERE=(libname='WORK' AND memname='REVISED_CHARACTER' AND typemem='DATA'));
	CALL SYMPUT("label&stat","Revised Character");
	CALL SYMPUT("figure&stat",filesize);
RUN;

QUIT;

%PUT &stat &&label&stat &&figure&stat;

*** Eliminate unneeded data sets ***;
PROC DELETE DATA=character;
RUN;

QUIT;

PROC DELETE DATA=character2;
RUN;

QUIT;

*** Vertically concatenate the numeric and character variables  ***;

DATA revised_all;
	MERGE revised_numeric revised_character;
RUN;

QUIT;

*** Check the space and metadata to compare the results  ***;
PROC CONTENTS DATA=revised_all OUT=revised_all_contents;
RUN;

QUIT;

*** Make sure the values have not changed ***;
PROC COMPARE BASE=x COMPARE=revised_all OUT=all_comparison;
RUN;

QUIT;

PROC COMPARE BASE=x COMPARE=revised_all OUT=all_comparison_outnoequal OUTNOEQUAL;
RUN;

QUIT;

*** Update the tracker for the sizes ***;
%LET stat=%EVAL(&stat+1);

*** Save the size of the data set ***;
DATA _NULL_;
	SET sashelp.vtable(WHERE=(libname='WORK' AND memname='REVISED_ALL' AND typemem='DATA'));
	CALL SYMPUT("label&stat","Revised Concatenated");
	CALL SYMPUT("figure&stat",filesize);
RUN;

QUIT;

%PUT &stat &&label&stat &&figure&stat;

*** Make sure the values have not changed ***;
** Set the output variable for mismatches ***;
%LET diag=%EVAL(&diag+1);

DATA _NULL_;
	CALL SYMPUT("diaglbl&diag","After Combined Compare");
	CALL SYMPUT("diagamt&diag",missobs&diag);
	STOP;
	SET all_comparison_outnoequal NOBS=missobs&diag;
RUN;

QUIT;

%PUT &diag &&diaglbl&diag &&diagamt&diag;

*** No longer needed for comparison;
PROC DELETE DATA=x;
RUN;

QUIT;

*** Numeric variables with non-negative integer values <= 99 can be put into character
variables with length 1 or 2.  3 is the lowest length for numeric variables ***;
%MACRO NUMTOCHAR;

	DATA revised_numeric2;
		LENGTH 
			%DO I=1 %TO &ncount;

		%IF &&int_check_min&i=1 %THEN
			%DO;
				%IF &&integer_min&i>=0 %THEN
					%DO;
						%IF &&integer_max&i<=9 %THEN
							%DO;
								&&nv&i $ 1
							%END;
						%ELSE %IF &&integer_max&i<=99 %THEN
							%DO;
								&&nv&i $ 2
							%END;
					%END;
			%END;
%END;
		;
		SET revised_numeric(RENAME=(
		%DO I=1 %TO &ncount;
		%IF &&int_check_min&i=1 %THEN

			%DO;
				%IF &&integer_min&i>=0 %THEN
					%DO;
						%IF &&integer_max&i<=99 %THEN
							%DO;
								&&nv&i=&&nsfx&i
							%END;
					%END;
			%END;
%END;
		));
		%DO I=1 %TO &ncount;
			%IF &&int_check_min&i=1 %THEN
				%DO;
					%IF &&integer_min&i>=0 %THEN
						%DO;
							%IF &&integer_max&i<=99 %THEN
								%DO;
									&&nv&i=&&nsfx&i;
								%END;
						%END;
				%END;
		%END;
	RUN;

	QUIT;

%MEND NUMTOCHAR;

%NUMTOCHAR;

*** PROC COMPARE will not apply where the type changed between character and numeric ***;
*** The macro below does the comparison and then removes the temporary variables ***;
%MACRO CHKNUMTOCHAR;

	DATA check_character;
		RETAIN flag
			%DO I=1 %TO &ncount;

		%IF &&int_check_min&i=1 %THEN
			%DO;
				%IF &&integer_min&i>=0 %THEN
					%DO;
						%IF &&integer_max&i<=99 %THEN
							%DO;
								&&nv&i &&nsfx&i
							%END;
					%END;
			%END;
%END;
		;
		SET revised_numeric2;
		flag=0;

		%DO I=1 %TO &ncount;
			%IF &&int_check_min&i=1 %THEN
				%DO;
					%IF &&integer_min&i>=0 %THEN
						%DO;
							%IF &&integer_max&i<=99 %THEN
								%DO;
									IF &&nv&i^=&&nsfx&i THEN
										flag=1;
								%END;
						%END;
				%END;
		%END;

		IF flag=1;
		KEEP flag
			%DO I=1 %TO &ncount;

		%IF &&int_check_min&i=1 %THEN
			%DO;
				%IF &&integer_min&i>=0 %THEN
					%DO;
						%IF &&integer_max&i<=99 %THEN
							%DO;
								&&nv&i &&nsfx&i
							%END;
					%END;
			%END;
%END;
		;
	RUN;

	QUIT;

	DATA revised_numeric2;
		SET revised_numeric2(KEEP=

			%DO	I=1 %TO &ncount;
			&&nv&i
			%END;
		);
	RUN;

	QUIT;

%MEND CHKNUMTOCHAR;

%CHKNUMTOCHAR;

** Set the output variable for mismatches ***;
%LET diag=%EVAL(&diag+1);

DATA _NULL_;
	CALL SYMPUT("diaglbl&diag","After Numeric to Character - Character");
	CALL SYMPUT("diagamt&diag",missobs&diag);
	STOP;
	SET check_character NOBS=missobs&diag;
RUN;

QUIT;

%PUT &diag &&diaglbl&diag &&diagamt&diag;

*** Check the space and metadata to compare the results  ***;
PROC CONTENTS DATA=revised_numeric2 OUT=revised_numeric2_contents;
RUN;

QUIT;

*** Make sure the values have not changed ***;
PROC COMPARE BASE=revised_numeric COMPARE=revised_numeric2 OUT=revised_numeric2_comparison;
RUN;

QUIT;

PROC COMPARE BASE=revised_numeric COMPARE=revised_numeric2 
	OUT=revised_numeric2_outnoequal OUTNOEQUAL;
RUN;

QUIT;

** Set the output variable for mismatches ***;
%LET diag=%EVAL(&diag+1);

DATA _NULL_;
	CALL SYMPUT("diaglbl&diag","After Numeric to Character - Numeric");
	CALL SYMPUT("diagamt&diag",missobs&diag);
	STOP;
	SET revised_numeric2_outnoequal NOBS=missobs&diag;
RUN;

QUIT;

%PUT &diag &&diaglbl&diag &&diagamt&diag;

*** Update the tracker for the sizes ***;
%LET stat=%EVAL(&stat+1);

*** Save the size of the data set ***;
DATA _NULL_;
	SET sashelp.vtable(WHERE=(libname='WORK' AND memname='REVISED_NUMERIC2' AND typemem='DATA'));
	CALL SYMPUT("label&stat","Revised Numeric after Character Conversion");
	CALL SYMPUT("figure&stat",filesize);
RUN;

QUIT;

%PUT &stat &&label&stat &&figure&stat;



*** To get the all-digit values of the character variables, we'll remove the digits and
and choose the those with no characters left ***;
%MACRO GETNUMCHAR;

	DATA character_digits;
		LENGTH 
			%DO I=1 %TO &ccount;
		len&i lend&i
		%END;
		3;
		SET revised_character;

		%DO I=1 %TO &ccount;
			len&i=lengthn(&&cv&i);
			comprs&i=compress(&&cv&i,,'d');
			lend&i=lengthn(comprs&i);
		%END;
	RUN;

	QUIT;

%MEND GETNUMCHAR;

%GETNUMCHAR;

%MACRO GETNUMCHAR2;
	*** See which variables are always all-digit ***;
	PROC SUMMARY MAX DATA=character_digits NWAY MISSING;
		VAR 
			%DO I=1 %TO &ccount;
		lend&i
		%END;
		;
		OUTPUT OUT=length_counts(DROP=_TYPE_ _FREQ_) 
			MAX=
			%DO I=1 %TO &ccount;
		character_digit_max&i
		%END;
		;
	RUN;

	QUIT;

	*** Get the maximum length **;
	PROC SUMMARY MAX DATA=character_digits NWAY MISSING;
		VAR 
			%DO I=1 %TO &ccount;
		len&i
		%END;
		;
		OUTPUT OUT=length_counts2(DROP=_TYPE_ _FREQ_) 
			MAX=
			%DO I=1 %TO &ccount;
		character_length_max&i
		%END;
		;
	RUN;

	QUIT;

%MEND GETNUMCHAR2;

%GETNUMCHAR2;

*** Create macro variables for the lengths  ***;
DATA chracter_numeric_lengths;
	MERGE length_counts length_counts2;
	ARRAY character_length_max character_length_max1-character_length_max&ccount;
	ARRAY character_digit_max character_digit_max1-character_digit_max&ccount;

	DO I=1 TO &ccount;
		CALL SYMPUT('character_length_max'||LEFT(PUT(i,4.)),character_length_max{i});
		CALL SYMPUT('character_digit_max'||LEFT(PUT(i,4.)),character_digit_max{i});
	END;

	DROP i;
RUN;

QUIT;

*** Change the selected variables to numeric variables ***;
***  Only those variables with length >=4 will benefit from the ocnversion to numeric ***;
%MACRO GETNUMCHAR3;

	DATA character2_numeric;
		SET revised_character(RENAME=(
		%DO I=1 %TO &ccount;
		%IF &&character_digit_max&i=0 %THEN

			%DO;
				%IF &&character_length_max&i>=4 %THEN
					%DO;
						&&cv&i=&&csfx&i
					%END;
			%END;
%END;
		));
		%DO I=1 %TO &ccount;
			%IF &&character_digit_max&i=0 %THEN
				%DO;
					%IF &&character_length_max&i>=4 %THEN
						%DO;
							&&cv&i=INPUT(&&csfx&i,20.);
						%END;
				%END;
		%END;
	RUN;

	QUIT;

	*** Calculate the maximum value of the numeric variable ***;
	PROC SUMMARY DATA=character2_numeric NWAY MISSING MAX;
		VAR
			%DO I=1 %TO &ccount;

		%IF &&character_digit_max&i=0 %THEN
			%DO;
				%IF &&character_length_max&i>=4 %THEN
					%DO;
						&&cv&i
					%END;
			%END;
%END;
		;
		OUTPUT OUT=character_numeric_max(DROP=_TYPE_ _FREQ_) MAX=
			%DO I=1 %TO &ccount;

		%IF &&character_digit_max&i=0 %THEN
			%DO;
				%IF &&character_length_max&i>=4 %THEN
					%DO;
						character_value_max&i
					%END;
			%END;
%END;
		;
%MEND GETNUMCHAR3;

%GETNUMCHAR3;

*** Create macro variables for the maximum character length ***;
DATA _NULL_;
	MERGE character_numeric_max chracter_numeric_lengths;
	ARRAY character_value_max character_value_max1-character_value_max&ccount;
	ARRAY character_length_max character_length_max1-character_length_max&ccount;
	ARRAY character_digit_max character_digit_max1-character_digit_max&ccount;

	DO I=1 TO &ccount;
		IF character_digit_max{i}=0 THEN
			DO;
				IF character_length_max{i}>=4 THEN
					DO;
						CALL SYMPUT('character_value_max'||LEFT(PUT(i,4.)),character_value_max{i});
					END;
			END;
	END;
RUN;

QUIT;

*** Use information from the SAS web site to calculate smallest length ***;
%MACRO GETNUMCHAR4;

	DATA revised_character2_numeric;
		LENGTH 
			%DO I=1 %TO &ccount;

		%IF &&character_digit_max&i=0 %THEN
			%DO;
				%IF &&character_length_max&i>=4 %THEN
					%DO;
						%IF &&character_value_max&i<8192 %THEN
							%DO;
								&&cv&i 3.
							%END;
						%ELSE %IF &&character_value_max&i<2097152 %THEN
							%DO;
								&&cv&i 4.
							%END;
						%ELSE %IF &&character_value_max&i<536870912 %THEN
							%DO;
								&&cv&i 5.
							%END;
						%ELSE %IF &&character_value_max&i<137438953472 %THEN
							%DO;
								&&cv&i 6.
							%END;
						%ELSE %IF &&character_value_max&i<35184372088832 %THEN
							%DO;
								&&cv&i 7.
							%END;
						%ELSE
							%DO;
								&&cv&i 8.
							%END;
					%END;
			%END;
%END;
		;
		SET character2_numeric;
	RUN;

	QUIT;

%MEND GETNUMCHAR4;

%GETNUMCHAR4;

*** PROC COMPARE will not apply where the type changed between character and numeric ***;
*** The macro below does the comparison and then removes the temporary variables ***;
%MACRO CHECKOUTPUT;

	DATA check_numeric;
		RETAIN flag
			%DO I=1 %TO &ccount;

		%IF &&character_digit_max&i=0 %THEN
			%DO;
				%IF &&character_length_max&i>=4 %THEN
					%DO;
						&&cv&i &&csfx&i
					%END;
			%END;
%END;
		;
		SET revised_character2_numeric;
		flag=0;

		%DO I=1 %TO &ccount;
			%IF &&character_digit_max&i=0 %THEN
				%DO;
					%IF &&character_length_max&i>=4 %THEN
						%DO;
							IF &&cv&i^=&&csfx&i THEN 
								flag=1;
						%END;
				%END;
		%END;

		IF flag=1;
		KEEP flag
			%DO I=1 %TO &ccount;

		%IF &&character_digit_max&i=0 %THEN
			%DO;
				%IF &&character_length_max&i>=4 %THEN
					%DO;
						&&cv&i &&csfx&i
					%END;
			%END;
%END;
		;
	RUN;

	QUIT;

	DATA revised_character2_numeric;
		SET revised_character2_numeric(KEEP=

			%DO	I=1 %TO &ccount;
				&&cv&i
			%END;
		);
	RUN;

	QUIT;

%MEND CHECKOUTPUT;

%CHECKOUTPUT;

** Set the output variable for mismatches ***;
%LET diag=%EVAL(&diag+1);

DATA _NULL_;
	CALL SYMPUT("diaglbl&diag","After Character to Numeric - Numeric");
	CALL SYMPUT("diagamt&diag",missobs&diag);
	STOP;
	SET check_numeric NOBS=missobs&diag;
RUN;

QUIT;

%PUT &diag &&diaglbl&diag &&diagamt&diag;

*** Check the space and metadata to compare the results  ***;
PROC CONTENTS DATA=revised_character2_numeric OUT=revised_character2_numeric_cont;
RUN;

QUIT;

*** Make sure the values have not changed ***;
PROC COMPARE BASE=revised_character COMPARE=revised_character2_numeric OUT=character_comparison2;
RUN;

QUIT;

PROC COMPARE BASE=revised_character COMPARE=revised_character2_numeric OUTNOEQUAL
	OUT=character_comparison2_outnoequal;
RUN;

QUIT;

** Set the output variable for mismatches ***;
%LET diag=%EVAL(&diag+1);

DATA _NULL_;
	CALL SYMPUT("diaglbl&diag","After Character to Numeric - Character");
	CALL SYMPUT("diagamt&diag",missobs&diag);
	STOP;
	SET character_comparison2_outnoequal NOBS=missobs&diag;
RUN;

QUIT;

%PUT &diag &&diaglbl&diag &&diagamt&diag;

*** Save the size of the data set ***;
%LET stat=%EVAL(&stat+1);

DATA _NULL_;
	SET sashelp.vtable(WHERE=(libname='WORK' AND memname='REVISED_CHARACTER2_NUMERIC' 
		AND typemem='DATA'));
	CALL SYMPUT("label&stat","Revised Character after Numeric Conversion");
	CALL SYMPUT("figure&stat",filesize);
RUN;
QUIT;

%PUT &stat &&label&stat &&figure&stat;

*** Vertically concatenate the numeric and character variables  ***;
***  Produce the output file ***;
***  Check which SAS data sets are smaller ***;

*** Test ***;
DATA stevetest1;
     MERGE revised_numeric revised_character;
RUN;
QUIT;

DATA stevetest2;
     MERGE revised_numeric2 revised_character;
RUN;
QUIT;

DATA stevetest3;
     MERGE revised_numeric revised_character2_numeric;
RUN;
QUIT;


DATA stevetest4;
     MERGE revised_numeric2 revised_character2_numeric;
RUN;
QUIT;

PROC SQL;
     CREATE TABLE test_ds AS
	 SELECT memname, filesize FROM sashelp.vtable 
	 WHERE libname='WORK' AND UPCASE(memname) IN 
		("STEVETEST1","STEVETEST2","STEVETEST3","STEVETEST4") 
		AND typemem='DATA';
	 CREATE TABLE smallest_ds AS
	 SELECT memname FROM test_ds 
	 WHERE filesize =
	 SELECT MIN(filesize)FROM test_ds;
QUIT;

DATA _NULL_;
     SET smallest_ds;
	 CALL SYMPUT("smallest",memname);
RUN;
QUIT;

%PUT &smallest;

DATA OUT.&outds;
	SET &smallest;  
RUN;
QUIT;

*** Check the space and metadata to compare the results  ***;
PROC CONTENTS DATA=OUT.&outds OUT=&outds._contents; 
RUN;

QUIT;

*** Make sure the values have not changed ***;
PROC COMPARE BASE=revised_all COMPARE=OUT.&outds OUT=all_comparison;
RUN;
QUIT;

PROC COMPARE BASE=revised_all COMPARE=OUT.&outds OUT=all_comparison_outnoequal OUTNOEQUAL;
RUN;
QUIT;

** Set the output variable for mismatches ***;
%LET diag=%EVAL(&diag+1);

DATA _NULL_;
	CALL SYMPUT("diaglbl&diag","Final Data Set");
	CALL SYMPUT("diagamt&diag",missobs&diag);
	STOP;
	SET all_comparison_outnoequal NOBS=missobs&diag;
RUN;

QUIT;

%PUT &diag &&diaglbl&diag &&diagamt&diag;

*** Save the size of the data set ***;
%LET stat=%EVAL(&stat+1);

DATA _NULL_;
	SET sashelp.vtable(WHERE=(libname='OUT' AND memname=UPCASE("&outds")
		AND typemem='DATA'));
	CALL SYMPUT("label&stat","Final Data Set");
	CALL SYMPUT("figure&stat",filesize);
RUN;
QUIT;

%PUT &stat &&label&stat &&figure&stat;


*** Create output files with statistics and dagnostics ***;
%MACRO STATDIAG;
DATA out.&outds._stats;
     LENGTH statistic $ 50;
     %DO I=1 %TO &stat;
         statistic="&&label&i";
		 value=&&figure&i;
		 OUTPUT;
	  %END;
RUN;
QUIT;

DATA out.&outds._diags;
      LENGTH diagnostic $ 50;
      %DO I=1 %TO &diag;
	      diagnostic="&&diaglbl&i";
		  mismatches=&&diagamt&i;
		  OUTPUT;
	  %END;
RUN;
QUIT;
%MEND STATDIAG;

%STATDIAG;

*** Clear space by deleting unneeded data sets ***;

PROC DELETE DATA=revised_all;
RUN;
QUIT;

PROC DELETE DATA=revised_numeric2;
RUN;
QUIT;

PROC DELETE DATA=revised_character2_numeric;
RUN;
QUIT;

** Eliminate unneeded data set to save space ***;
PROC DELETE DATA=revised_character;
RUN;
QUIT;

PROC DELETE DATA=revised_numeric;
RUN;
QUIT;