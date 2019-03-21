
/*--Diagram Counts--*/
data info;
  length Stage $12 Arm $12;
  input Stage $ Arm $ n1-n5;
  /* Stage and Study must be in correct order */
  datalines;          /* Your n1-n5 counts */
Enrollment  Assessed    445    .    .   .   .
Enrollment  Excluded     39   22   14   3   .
Enrollment  Randomized  406    .    .   .   .
Allocation  Placebo      96   90    6   .   .
Allocation  ARM-1       103  103    0   .   .
Allocation  ARM-2       105   98    7   .   .
Allocation  ARM-3       102  101    1   .   .
Follow-Up   Placebo      10    2    4   0   4
Follow-Up   ARM-1         7    3    2   1   1
Follow-Up   ARM-2        11    5    2   1   3
Follow-Up   ARM-3        16    7    6   2   1
Analysis    Placebo      89    7   90   6   .
Analysis    ARM-1       100    3  103   0   .
Analysis    ARM-2        98    7   98   7   .
Analysis    ARM-3        92   10  101   1   .
;  
run;

/*--Compute Consort Data--*/
%consortData(inData=info, outData=consort4_4, arms=4, nColumns=4);

/*--Draw the Consort diagram--*/
title 'CONSORT Diagram for a 4 Arm Study';
%consortDiagram(diagData=consort4_4);
