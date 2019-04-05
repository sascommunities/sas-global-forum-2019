%let gpath=".";
%let dpi=300;
ods _all_ close;
ods listing gpath=&gpath image_dpi=&dpi;

data TumorSize;
  length cId $ 3;
  label Change='Change from Baseline (%)' Drop='Dropped';
  drop i grp1-grp2 l1-l4;
  array groupArr{*} $12 grp1-grp2 ('Treatment A', 'Treatment B');
  array labelArr{*} $ l1 - l4 ('CR', 'PR', 'SD', 'PD');
  
  do i=1 to 25;
    cId=put(i, 2.0);
    Change = 30-120*ranuni(2);
    Group = groupArr{int(ranuni(2)+0.5) + 1}; 
    Label = labelArr{mod(i, 4) + 1};
    Duration = floor(50+100*ranuni(2));
    Drop = ifn(ranuni(2) < 0.3, floor(duration-10), .);
    output;
  end;
run;

proc sort data=TumorSize out=TumorSizeSort;
  by descending change;
run;


/*--Change in Tumor Size with Duration--*/
ods listing style=listing;
ods graphics / reset width=5in height=3.5in imagename='TumorSize_Duration_SG';

title 'Tumor Response and Duration by Subject Id';
footnote j=l italic 'This graph uses simulated data for illustration only';

proc sgplot data=TumorSizeSort nowall noborder nocycleAttrs;

  styleAttrs dataColors=(cxbf0000 cx4f4f4f) dataContrastColors=(black) axisExtent=data;
  symbolChar name=mystar char='002a'x / vOffset=-0.5 scale=3;

  vBarParm category=cId response=duration / datalabel=duration y2Axis
             dataLabelAttrs=(size=5 weight=bold) fillAttrs=(color=cxcfcf7f);
  scatter x=cId y=drop / y2Axis markerAttrs=(symbol=mystar color=red size=9);

          /* groupDisplay=cluster allows dataLabel */
  vBarParm category=cId response=change / group=group datalabel=label
             dataLabelAttrs=(size=5 weight=bold) groupDisplay=cluster clusterWidth=0.9;
  refLine 20 -30 / lineAttrs=(pattern=shortDash) transparency=0.2;

  xAxis display=none colorBands=odd colorBandsAttrs=(transparency=0.2);
  yAxis values=(60 to -100 by -20) offsetMax=0.36 labelPos=dataCenter;
  y2Axis offsetMin=0.66  labelPos=dataCenter;

  inset ("CR="="Complete Response" "PR="="Partial Response"
          "SD="="Stable Disease" "PD="="Progressive Disease") / title='BCR' 
        position=bottomLeft border textAttrs=(size=6) titleAttrs=(size=7)
        valueAlign=left;
  keyLegend / title='' border;

run;
title;
footnote;
