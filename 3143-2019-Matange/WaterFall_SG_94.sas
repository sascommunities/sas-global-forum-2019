%let gpath='C:\Work\Sugi\SGF2016\SuperDemos\Clinical_Graphs\Image';
%let dpi=300;
ods html close;
ods listing gpath=&gpath image_dpi=&dpi;

data TumorSize;
  length Cid $ 3;
  label Change='Change from Baseline (%)';
  do Id=1 to 25;
    cid=put(id, 2.0);
    change=30-120*ranuni(2);
        Group=ifc(int(ranuni(2)+0.5), 'Treatment 1', 'Treatment 2');
        if mod(id, 5) = 1 then Label='C';
        if mod(id, 5) = 2 then label='R';
        if mod(id, 5) = 3 then label='S';
        if mod(id, 5) = 4 then label='P';
        if mod(id, 5) = 0 then label='E';
        output;
  end;
run;

ods html;
proc print data=TumorSize(obs=5);
run;
ods html close;

/*--Change in Tumor Size--*/
ods listing style=listing;
ods graphics / reset width=5in height=3in imagename='TumorSize_SG_V94';
title 'Change in Tumor Size';
title2 'ITT Population';
proc sgplot data=TumorSize nowall noborder;
  styleattrs datacolors=(cxbf0000 cxafafaf) datacontrastcolors=(black);
  vbar cid / response=change group=group categoryorder=respdesc datalabel=label
             datalabelattrs=(size=5 weight=bold) groupdisplay=cluster clusterwidth=1;
  refline 20 -30 / lineattrs=(pattern=shortdash);
  xaxis display=none;
  yaxis values=(60 to -100 by -20);
  inset "C= Complete Response" "R= Partial Response" "S= Stable Disease" 
        "P= Progressive Disease" "E= Early Death" / title='BCR'
         position=bottomleft border textattrs=(size=6 weight=bold) titleattrs=(size=7);
  keylegend / title='' location=inside position=topright across=1 border;
run;
title;

proc sort data=TumorSize out=TumorSizeDesc;
  by descending change;
run;

ods listing style=listing;
ods graphics / reset width=5in height=3in imagename='TumorSize_Band_SG_V94';
title 'Change in Tumor Size';
title2 'ITT Population';
proc sgplot data=TumorSizeDesc nowall noborder;
  styleattrs datacolors=(cxbf0000 gold) datacontrastcolors=(black) axisextent=data;
  band x=cid upper=20 lower=-30 / transparency=0.5 fill nooutline legendlabel='Confidence';
  vbarparm category=cid  response=change / group=group datalabel=label
             datalabelattrs=(size=5 weight=bold) groupdisplay=cluster
             dataskin=pressed;
  xaxis display=none;
  yaxis values=(60 to -100 by -20) grid gridattrs=(color=cxf0f0f0);
  inset "C= Complete Response" "R= Partial Response" "S= Stable Disease" 
        "P= Progressive Disease" "E= Early Death" / title='BCR'
         position=bottomleft border textattrs=(size=6 weight=bold) titleattrs=(size=7);
  keylegend / title='' location=inside position=topright across=1 border opaque;
run;
title;
