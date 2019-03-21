
/*--Diagram Counts--*/
data info;
  length Stage $12 Arm $12;
  input Stage $ Arm $ n1-n5;

  /* Stage and Study must be in correct order */
  datalines;          /* Your n1-n5 counts */
Enrollment  Assessed    237    .    .   .   .
Enrollment  Excluded     39   22   14   3   .
Enrollment  Randomized  198    .    .   .   .
Allocation  Placebo      95   90    5   .   .
Allocation  ARM-1       103  103    0   .   .
Follow-Up   Placebo      10    2    4   9   5
Follow-Up   ARM-1         7    3    2   1   1
Analysis    Placebo      89    7   90   6   .
Analysis    ARM-1       100    2  103   0   .
;  
run;

/*--Compute Consort Data--*/
%consortData(inData=info, outData=consort2_3, arms=2, nColumns=3);
%consortData(inData=info, outData=consort2_4, arms=2, nColumns=4);

/*--Draw the Consort diagram--*/
title "CONSORT Diagram for a 2 Arm Study (3 column layout)";
%consortDiagram(diagData=consort2_3, fillColor=liybr);

title "CONSORT Diagram for a 2 Arm Study (4 column layout)";
%consortDiagram(diagData=consort2_4, fillColor=liybr);
