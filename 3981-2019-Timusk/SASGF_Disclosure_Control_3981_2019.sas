*Program: \\Presentations\SASGlobalForum\2019\SASGF_Disclosure_Control_3981_2019.sas

 Purpose: To run the example from SASGF_Disclosure_Control_3981_2019.docx (Peter Timusk)
          in G-Confid.

 Author: Alex Davies, Centre For Special Business Projects;

libname discarch '\\Presentations\SASGlobalForum\2019\FakeData';

data disc;
  do i=1 to 10; province='NL'; naics='11'; enterprise=1; output; end;
  do i=1 to 21; province='NL'; naics='21'; enterprise=1; output; end;
  do i=1 to 3; province='NL'; naics='22'; enterprise=1; output; end;
  do i=1 to 12; province='NL'; naics='23'; enterprise=1; output; end;
  do i=1 to 420; province='NL'; naics='31'; enterprise=1; output; end;
  do i=1 to 816; province='NL'; naics='44'; enterprise=1; output; end;

  do i=1 to 78; province='PE'; naics='11'; enterprise=1; output; end;
  do i=1 to 15; province='PE'; naics='21'; enterprise=1; output; end;
  do i=1 to 4; province='PE'; naics='22'; enterprise=1; output; end;
  do i=1 to 2; province='PE'; naics='23'; enterprise=1; output; end;
  do i=1 to 267; province='PE'; naics='31'; enterprise=1; output; end;
  do i=1 to 390; province='PE'; naics='44'; enterprise=1; output; end;

  do i=1 to 86; province='NS'; naics='11'; enterprise=1; output; end;
  do i=1 to 20; province='NS'; naics='21'; enterprise=1; output; end;
  do i=1 to 1; province='NS'; naics='22'; enterprise=1; output; end;
  do i=1 to 2; province='NS'; naics='23'; enterprise=1; output; end;
  do i=1 to 504; province='NS'; naics='31'; enterprise=1; output; end;
  do i=1 to 2398; province='NS'; naics='44'; enterprise=1; output; end;

  do i=1 to 127; province='NB'; naics='11'; enterprise=1; output; end;
  do i=1 to 34; province='NB'; naics='21'; enterprise=1; output; end;
  do i=1 to 2; province='NB'; naics='22'; enterprise=1; output; end;
  do i=1 to 4; province='NB'; naics='23'; enterprise=1; output; end;
  do i=1 to 430; province='NB'; naics='31'; enterprise=1; output; end;
  do i=1 to 2398; province='NB'; naics='44'; enterprise=1; output; end;

  do i=1 to 7689; province='QC'; naics='11'; enterprise=1; output; end;
  do i=1 to 78; province='QC'; naics='21'; enterprise=1; output; end;
  do i=1 to 45; province='QC'; naics='22'; enterprise=1; output; end;
  do i=1 to 65; province='QC'; naics='23'; enterprise=1; output; end;
  do i=1 to 4029; province='QC'; naics='31'; enterprise=1; output; end;
  do i=1 to 18000; province='QC'; naics='44'; enterprise=1; output; end;

  do i=1 to 6790; province='ON'; naics='11'; enterprise=1; output; end;
  do i=1 to 121; province='ON'; naics='21'; enterprise=1; output; end;
  do i=1 to 54; province='ON'; naics='22'; enterprise=1; output; end;
  do i=1 to 47; province='ON'; naics='23'; enterprise=1; output; end;
  do i=1 to 4398; province='ON'; naics='31'; enterprise=1; output; end;
  do i=1 to 29909; province='ON'; naics='44'; enterprise=1; output; end;

  do i=1 to 1780; province='MB'; naics='11'; enterprise=1; output; end;
  do i=1 to 209; province='MB'; naics='21'; enterprise=1; output; end;
  do i=1 to 34; province='MB'; naics='22'; enterprise=1; output; end;
  do i=1 to 49; province='MB'; naics='23'; enterprise=1; output; end;
  do i=1 to 1987; province='MB'; naics='31'; enterprise=1; output; end;
  do i=1 to 2890; province='MB'; naics='44'; enterprise=1; output; end;

  do i=1 to 2499; province='SK'; naics='11'; enterprise=1; output; end;
  do i=1 to 125; province='SK'; naics='21'; enterprise=1; output; end;
  do i=1 to 56; province='SK'; naics='22'; enterprise=1; output; end;
  do i=1 to 30; province='SK'; naics='23'; enterprise=1; output; end;
  do i=1 to 2098; province='SK'; naics='31'; enterprise=1; output; end;
  do i=1 to 4002; province='SK'; naics='44'; enterprise=1; output; end;

  do i=1 to 1760; province='AB'; naics='11'; enterprise=1; output; end;
  do i=1 to 1209; province='AB'; naics='21'; enterprise=1; output; end;
  do i=1 to 230; province='AB'; naics='22'; enterprise=1; output; end;
  do i=1 to 46; province='AB'; naics='23'; enterprise=1; output; end;
  do i=1 to 3879; province='AB'; naics='31'; enterprise=1; output; end;
  do i=1 to 2098; province='AB'; naics='44'; enterprise=1; output; end;

  do i=1 to 1430; province='BC'; naics='11'; enterprise=1; output; end;
  do i=1 to 276; province='BC'; naics='21'; enterprise=1; output; end;
  do i=1 to 156; province='BC'; naics='22'; enterprise=1; output; end;
  do i=1 to 89; province='BC'; naics='23'; enterprise=1; output; end;
  do i=1 to 1209; province='BC'; naics='31'; enterprise=1; output; end;
  do i=1 to 6789; province='BC'; naics='44'; enterprise=1; output; end;

  do i=1 to 3; province='YT'; naics='11'; enterprise=1; output; end;
  do i=1 to 650; province='YT'; naics='21'; enterprise=1; output; end;
  do i=1 to 145; province='YT'; naics='22'; enterprise=1; output; end;
  do i=1 to 23; province='YT'; naics='23'; enterprise=1; output; end;
  do i=1 to 879; province='YT'; naics='31'; enterprise=1; output; end;
  do i=1 to 2098; province='YT'; naics='44'; enterprise=1; output; end;
run;

data disc; set disc; uniqueid=trim(left(_n_)); run;

%macro confid_disc(var);
		proc sensitivity
		  data=disc(where=(&var > 0))
		  outconstraint=cons_&var.
		  outcell=outc_&var.
		  outlargest=larg_&var.
		  hierarchy="AI 11 21 22 23 31 44;
                     CA NL PE NS NB QC ON MB SK AB BC YT;"
		  srule="pq 0.2"
		  minresp=3
		  m=5
		  x=0
		  y=0
		  z=0;
		  id uniqueid;
		  var &var;
		  dimension naics province;
		run;

  data outc_&var.;
    set outc_&var.;
    cost1=NbRespondents;
  run;

		%Suppress(InCell=outc_&var.,
                  constraint=cons_&var.,
                  CFunction1=DIGITS,
                  CFunction2=INFORMATION,
                  CVar1=Cost1,
                  CVar2=Cost1,
                  PrintProgress=YES,
                  OutCell=discarch.disc_&var.);

title &var;
proc print data=discarch.disc_&var.; where status='S' or outstatus='X'; run;
title;
%mend confid_disc;

%confid_disc(enterprise);


  
