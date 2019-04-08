%let gpath=".";
%let dpi=300;
ods _all_ close;
ods listing gpath=&gpath image_dpi=&dpi;

/*--Add "Id" to identify subgroup headings from values                 --*/
data forest_subgroup;
  label PCIGroup='PCI Group' Group='Therapy Group';
  input Id Subgroup $3-27 Count Percent Mean  Low High PCIGroup Group PValue;
  datalines;
1 Overall                  2166  100  1.3   0.9   1.5  17.2  15.6   .
1 Age                       .     .    .     .     .    .     .     0.05
2 <= 65 Yr                 1534   71  1.5   1.05  1.9  17.0  13.2   .
2 > 65 Yr                   632   29  0.8   0.6   1.25 17.8  21.3   .
1 Sex                       .     .    .     .     .    .     .     0.13
2 Male                     1690   78  1.5   1.05  1.9  16.8  13.5   .
2 Female                    476   22  0.8   0.6   1.3  18.3  22.9   . 
1 Race or ethnic group      .     .    .     .     .    .     .     0.52
2 Nonwhite                  428   20  1.05  0.6   1.8  18.8  17.8   .
2 White                    1738   80  1.2   0.85  1.6  16.7  15.0   . 
1 From MI to Randomization  .     .    .     .     .    .     .     0.81
2 <= 7 days                 963   44  1.2   0.8   1.5  18.9  18.6   .
2 > 7 days                 1203   56  1.15  0.75  1.5  15.9  12.9   .
1 Diabetes                  .     .    .     .     .    .     .     0.41
2 Yes                       446   21  1.4   0.9   2.0  29.3  23.3   .
2 No                        720   79  1.1   0.8   1.5  14.4  13.5   .
;
run;

/*--Set indent weight, add insets and horizontal bands--*/
data forest_subgroup_2;
  set forest_subgroup end=last;
  label countPct='No. of Patients (%)';
  length tValue $20 tPos $8;
  drop Count Percent val;

  yVal=_n_; 
  if count ne . then CountPct=put(count, 4.0) || "(" || put(percent, 3.0) || ")";
  indentWt=ifn(id EQ 1, 0, 1);  /* indent sub headings */
  val=mod(_N_-1, 6);
  if val in (1:3) then ref=yVal;
  output;

  if last then do;
    call missing (Id, subGroup, mean, low, high, pcigroup, group, countPct, indentWt, ref);
	  yVal+1; 
    xl=0.9; tValue='<--PCI Better'; tPos='left'; output;
	  xl=1.1; tValue='Therapy Better-->'; tPos='right'; output;
  end;
run;

data attrmap;
  length textweight $10;
  id='text'; value='1'; textcolor='Black'; textsize=7; textweight='bold'; output;
  id='text'; value='2'; textcolor='Black'; textsize=5; textweight='normal'; output;
run;


/*--Forest Plot--*/
options missing=' ';
ods listing style=htmlBlue;
ods graphics / reset width=5in height=3in imagename='Forest_Subgrouped_SG_V94';
footnote j=l h=6pt italic 'This visual is for discussion of graph features only.'  
         '  The actual details should be customized by user to suit their application.';
proc sgplot data=forest_subgroup_2 noWall noBorder noCycleAttrs
                  dAttrMap=attrMap noAutoLegend ;
  styleAttrs axisExtent=data;
  refLine ref / lineAttrs=(color=cxe7e7f7) discretethickness=1;
  highlow y=yVal low=low high=high; 
  scatter y=yVal x=mean / markerAttrs=(symbol=squarefilled size=4);
  refLine 1 / axis=x;
  refLine 1 / axis=x2 noclip transparency=1; /* dummy for x2 axis label */
  text x=xl y=yVal text=tValue / position=tPos contributeoffsets=none;

  yAxistable subgroup  / location=inside position=left textGroup=id labelAttrs=(size=8) 
             textGroupId=text indentWeight=indentWt;
  yAxistable countpct / location=inside position=left labelAttrs=(size=8) valueAttrs=(size=7) valueJustify=right;
  yAxistable PCIGroup group pvalue / location=inside position=right labelAttrs=(size=8) valueAttrs=(size=7);

                  /* colorBands force axistable inner margin to be not opaque */
  yAxis reverse display=none type=discrete colorbands=odd colorBandsAttrs=(transparency=1);
  xAxis display=(nolabel) type=log values=( 0.5 1.0 2.0 4);
  x2Axis label='Hazard Ratio' display=(noline noticks novalues) labelAttrs=(size=8);
run;

title;
footnote;
