*  Close all ODS destinations, and then open when needed;

ods _all_ close;

*  Direct ODS output to the Results window;

ods results;

*  Directory of input and output files;

%let PATH=C:\HOW\DelGobbo;

*  Library for input data;

libname sample "&PATH" access=read;

;*';*";*/;quit;run;
* Reference for code above: http://tinyurl.com/mjde9fc ;