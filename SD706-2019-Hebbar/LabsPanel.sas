%let gpath='.';
%let dpi=300;

ods _all_ close;
ods listing style=htmlblue image_dpi=&dpi gpath=&gpath; 

proc format;
  value num2visit
     1='PreRx'
     2='Week 1'
     3='Week 2'
     4='Week 3'
     5='Week 5'
     6='Week 6'
     ;

  value $testNameWithUnit
        /* ODS Unicode escapes in formats! */
     'WBC' = "WBC x 10(*ESC*){Unicode '00b3'x} /uL"
     'Hemoglobin' = 'Hgb g/dL'
     ;
run;

/* Read in the CSV file -- input data */
%let dataDir=<your CSV file folder>;
proc import dataFile="&dataDir\labsPanel_data.csv" dbms=csv out=labs replace;
run;

proc sort data=labs;
  by testName visitNum;
run;

data labs_mod;
  format cellLabel $testNameWithUnit. visitNum num2Visit.;
  set labs;
  by testName;

  if first.testName or last.testName then do;
    bandLow = numLow;
    bandHigh = numHigh;
  end;
  if first.testName then cellLabel=testName;
run;


option nobyline;


/*--Panel with Class labels--*/
ods graphics / reset noborder width=5in height=2.25in imageName='WBC_Panel_Band_Box_NoHeader';
title 'WBC and Differential: Weeks 1-6';
proc sgpanel data=labs_mod noAutoLegend;
  panelby testName / onePanel uniscale=column layout=rowLattice
                    noHeader spacing=5;

  band x=visitNum lower=bandLow upper=bandHigh / transparency=0.7 
                                  fillAttrs=(color=lightGreen);

  refLine bandLow / label noClip lineAttrs=(color=lightGreen)
                      labelAttrs=(size=7) transparency=0.7;
  refLine bandHigh / label noClip  lineAttrs=(color=lightGreen)
                      labelAttrs=(size=7) transparency=0.7;

  scatter x=visitNum y=result / transparency=0.8 jitter;
  vbox result / category=visitNum noFill noOutliers lineAttrs=graphDataDefault;

  inset cellLabel / position=topLeft noLabel textAttrs=(size=9);

  rowAxis display=(noLine noLabel noTicks) offsetMax=0.18 valueAttrs=(size=7)
                                                grid gridAttrs=(pattern=dot);
  colAxis display=(noLine noLabel noTicks)  valueAttrs=(size=7);
run;

title;
footnote;

