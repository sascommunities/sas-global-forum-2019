%let gpath='.';
%let dpi=300;

ods _all_  close;
ods listing gpath=&gpath image_dpi=&dpi;

/* Creating dummy data for graphing */
data TumorSize;
  length Cid $ 3;
  label Change='Change from Baseline (%)';
  drop i grp1-grp2 l1-l5;
  array groupArr{*} $12 grp1-grp2 ('Treatment 2', 'Treatment 1');
  array labelArr{*} $ l1 - l5 ('E', 'C', 'R', 'S', 'P');
  do i=1 to 25;
    Cid = put(i, 2.0);
    Change = 30-120*ranuni(2);
    Group = groupArr{int(ranuni(2)+0.5) + 1};
	  Label = labelArr{mod(i, 5) + 1};
    output;
  end;
run;

proc sort data=TumorSize out=TumorSizeDesc;
  by descending change;
run;

ods listing style=listing;
ods graphics / reset width=5in height=3in imagename='TumorSize_Band_SG_V94';
title 'Change in Tumor Size';
title2 'ITT Population';
proc sgPlot data=TumorSizeDesc nowall noborder;
  styleattrs dataColors=(cxbf0000 gold) dataContrastColors=(black) axisExtent=data;
  band x=cid upper=20 lower=-30 / transparency=0.5 fill noOutline legendLabel='Confidence';
  vBarParm category=cid  response=change / group=group dataLabel=label
             dataLabelAttrs=(size=5 weight=bold) groupDisplay=cluster
             dataSkin=pressed;
  xaxis display=none;
  yaxis values=(60 to -100 by -20) grid gridAttrs=(color=cxf0f0f0);
  inset "C= Complete Response" "R= Partial Response" "S= Stable Disease" 
        "P= Progressive Disease" "E= Early Death" / title='BCR'
         position=bottomLeft border textAttrs=(size=6 weight=bold) titleAttrs=(size=7);
  keyLegend / title='' location=inside position=topRight across=1 border opaque;
run;
title;
