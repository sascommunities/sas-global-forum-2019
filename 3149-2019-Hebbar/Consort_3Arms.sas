/*-- Diagram Counts --*/
data info;
  length Stage $12 Arm $12;
  input Stage $ Arm $ n1-n5;
  /* Stage and Study must be in correct order */
  datalines;          /* Your n1-n5 counts */
Enrollment  Assessed    343    .    .   .   .
Enrollment  Excluded     39   22   14   3   .
Enrollment  Randomized  304    .    .   .   .
Allocation  Placebo      96   90    6   .   .
Allocation  ARM-1       103  103    0   .   .
Allocation  ARM-2       105   98    7   .   .
Follow-Up   Placebo      10    2    4   0   4
Follow-Up   ARM-1         7    3    2   1   1
Follow-Up   ARM-2        11    5    2   1   3
Analysis    Placebo      89    7   90   6   .
Analysis    ARM-1       100    3  103   0   .
Analysis    ARM-2        98    7   98   7   .
;  
run;

/*--Compute Consort Data--*/
%consortData(inData=info, outData=consort3_3, arms=3, nColumns=3);
%consortData(inData=info, outData=consort3_4, arms=3, nColumns=4);

/*--Draw the Consort diagram--*/
title 'CONSORT Diagram for a 3-Arm Study (3-column layout)';
%consortDiagram(diagData=consort3_3, fillColor=mog);

title 'CONSORT Diagram for a 3-Arm Study (4-column layout)';
%consortDiagram(diagData=consort3_4, fillColor=mog);
