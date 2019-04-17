/*The SAS code below is a modification of Prashant Hebbar's code 
from his Graphically Speaking blog entry titled 
"Is there a car on your radar?"*/

%let nVars=8; /* Number of variables */
data radarPoly;
  set hospital_rsrr;

  array hospRSRR[*] READM_30_HOSP_WIDE READM_30_AMI READM_30_CABG
                    READM_30_COPD READM_30_HF READM_30_HIP_KNEE 
                    READM_30_PN READM_30_STK;
  array nation[*] USA_HOSP_WIDE USA_AMI USA_CABG 
                  USA_COPD USA_HF USA_HIP_KNEE 
                  USA_PN USA_STK;
  array varNames[&nVars] $32 _temporary_ ("Hospital-Wide" "AMI" "CABG" 
                                          "COPD" "Heart Failure" "Hip/Knee" 
                                          "Pneumonia" "Stroke");
  array axisLabels[&nVars] $6 _temporary_ ("HW" "AMI" "CABG" 
                                           "COPD" "HF" "HK" 
                                           "PN" "SK");

  drop deg2Rad angleIncr startAngle idx angleRads xComp yComp
        rdX_start rdY_start rdX_start_nation rdY_start_nation 
        maxGridX_start maxGridY_start;
  retain deg2Rad angleIncr startAngle;

  if _n_ = 1 then
  do;
    deg2Rad = atan(1)/45;
    angleIncr = 360 * deg2Rad / &nVars;
    startAngle = 90 * deg2Rad;
  end;
  do idx = 1 to dim(hospRSRR);
    angleRads = startAngle + angleIncr * (idx - 1);
    xComp = cos(angleRads);
    yComp = sin(angleRads);
    rdX = hospRSRR[idx] * xComp;
    rdY = hospRSRR[idx] * yComp;
    rdX_nation = nation[idx] * xComp;
    rdY_nation = nation[idx] * yComp;
    if (idx = 1) then /* Store away the first pt */
    do;
      rdX_start = rdX;
      rdY_start = rdY;
      rdX_start_nation = rdX_nation;
      rdY_start_nation = rdY_nation;
    end;

    /* Parameter axis */
    radAxisX = 0.27 * xComp;
    radAxisY = 0.27 * yComp;
    radAxisLabel = axisLabels[idx];

    /* Parameter name */
    varName = varNames[idx];
    output;
  end;

    /* Reset values to avoid overwrites */
  radAxisX = . ; radAxisY = . ;

    /* Repeat the first pt */
  do;
    rdX = rdX_start;
    rdY = rdY_start;
    rdX_nation = rdX_start_nation;
    rdY_nation = rdY_start_nation;
    output;
  end;
    /* Reset values to avoid overwrites */
  rdX = . ; rdY = . ;
  rdX_nation = . ; rdY_nation = . ;

  /* Generate a 'circle' polygon:
   * sgpanel does not have ellipseParm */
  %let interPolate=6;
  do idx = 1 to &interPolate. * dim(hospRSRR);
    angleRads = startAngle + (angleIncr / &interPolate.) * (idx - 1);
    maxGridX = 0.25*cos(angleRads);
    maxGridY = 0.25*sin(angleRads);
    circGridX_1 = 0.05*cos(angleRads);
    circGridY_1 = 0.05*sin(angleRads);
    circGridX_2 = 0.10*cos(angleRads);
    circGridY_2 = 0.10*sin(angleRads);
    circGridX_3 = 0.15*cos(angleRads);
    circGridY_3 = 0.15*sin(angleRads);
    circGridX_4 = 0.20*cos(angleRads);
    circGridY_4 = 0.20*sin(angleRads);
    if (idx = 1) then /* Save the first pt */
    do;
      maxGridX_start = maxGridX;
      maxGridY_start = maxGridY;
      circGridX_start_1 = circGridX_1;
      circGridY_start_1 = circGridY_1;
      circGridX_start_2 = circGridX_2;
      circGridY_start_2 = circGridY_2;
      circGridX_start_3 = circGridX_3;
      circGridY_start_3 = circGridY_3;
      circGridX_start_4 = circGridX_4;
      circGridY_start_4 = circGridY_4;
    end;
    output;
  end;

  do; /* Repeat the first pt */
    maxGridX = maxGridX_start;
    maxGridY = maxGridY_start;
    circGridX_1 = circGridX_start_1;
    circGridY_1 = circGridY_start_1;
    circGridX_2 = circGridX_start_2;
    circGridY_2 = circGridY_start_2;
    circGridX_3 = circGridX_start_3;
    circGridY_3 = circGridY_start_3;
    circGridX_4 = circGridX_start_4;
    circGridY_4 = circGridY_start_4;
    output;
  end;
run;

ods graphics / reset height=5.25in width=7in;
proc sgpanel data=radarPoly subpixel;
  title "30-Day Risk-Standardized Readmission Rates for 6 NYC Hospitals";

  panelBy prov_id / columns=3 rows=2 sort=data noVarName spacing=4 noBorder 
                    headerattrs=(size=10pt) noheaderborder 
                    headerbackcolor=CXAFEEEE;
  colAxis display=none alternate values=(-0.27 to 0.27 by 0.03);
  rowAxis display=none alternate values=(-0.27 to 0.27 by 0.03);

  vector x=radAxisX y=radAxisY / xOrigin=0 yOrigin=0 noArrowHeads
            lineAttrs=(color=lightgray);

  series x=rdX y=rdY / name='hospital' 
            legendlabel="Hospital RSRR" lineAttrs=(thickness=2px);
  series x=rdX_nation y=rdY_nation / name='national' 
            legendlabel="National RR" lineAttrs=(thickness=2px 
              color=lightred pattern=dashdashdot);

  series x=maxGridX y=maxGridY       / lineAttrs=(color=lightGray) 
                                          curvelabel="25%";
  series x=circGridX_1 y=circGridY_1 / lineAttrs=(color=lightGray) 
                                          curvelabel="5%";
  series x=circGridX_2 y=circGridY_2 / lineAttrs=(color=lightGray);
                                        * curvelabel="10%";
  series x=circGridX_3 y=circGridY_3 / lineAttrs=(color=lightGray) 
                                      curvelabel="15%";
  series x=circGridX_4 y=circGridY_4 / lineAttrs=(color=lightGray);
                                        * curvelabel="20%";

  scatter x=radAxisX y=radAxisY / markerChar=radAxisLabel 
                                  markercharattrs=(size=9pt);

  keylegend 'hospital' 'national' / valueattrs=(size=9.5pt);

  footnote height=9.5pt "Measures: HW = Hospital-wide AMI = Acute myocardial
 infarction  CABG = Coronary artery bypass graft COPD = Chronic
 obstructive pulmonary disease HF = Heart failure  HK = Hip/knee
 arthroplasty  PN = Pneumonia  SK = Stroke";
run;
