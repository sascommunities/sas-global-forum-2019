%let gpath='.';
%let dpi=300;
ods listing style=htmlblue image_dpi=&dpi gpath=&gpath; 
ods html close;

proc format;
  value $drug
    'A'='Drug A (N=209)'
    'B'='Drug B (N=405)';
run;

/*--Generate some data--*/
data LFTShift;
  keep Base Max Test Drug;
  length Test $8;
  label Base="Baseline (/ULN)";
  label Max= "Maximum (/ULN)";

  do Test= 'ALAT', 'ALKPH', 'ASAT', 'BILTOT';
    do i=1 to 40;
      do Drug = 'A', 'B';
        Max = ranuni(5) + 0.1;
        Base = Max - ranuni(2) + 0.3;
        output;
      end;
    end;
  end;
run;


/*--Add reference lines to data by test--*/
data LFTShift_Ref;
  set LFTShift;
  by test;
  if first.test then do;
    Ref=1; output;
    Ref=ifn(test eq 'BILTOT', 1.5, 2); output;
  end;
  else output;
run;

/*--Panel with varying ref lines--*/
ods graphics / reset width=6in height=2.7in  imagename="Panel_of_LFT_Shift_Ref";
title "LFT Shifts from Baseline to Maximum by Treatment";
footnote1 j=l "Clincal Concern Levels: ALAT, ASAT, ALKPH = 2 ULN, BILTOT = 1.5 ULN";
footnote2 j=c "-- where ULN is the Upper Level of Normal Range";

proc sgPanel data=LFTShift_Ref;
  format Drug $drug.;
  panelBy Test / layout=panel columns=4 spacing=10 noVarName;

  lineParm x=0 y=0 slope=1 / lineattrs=graphgridlines; 
  scatter x=base y=max / group=drug;
  refLine ref / axis=Y lineAttrs=(pattern=dash); 
  refLine ref / axis=X lineAttrs=(pattern=dash);
  rowAxis integer min=0 max=4;
  colAxis integer min=0 max=4;
  keyLegend / title="" noborder;
run;

title;
footnote;
