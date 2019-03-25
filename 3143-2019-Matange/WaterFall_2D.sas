%let gpath=\\sashq\root\dept\dvr\DVR_Knowledge_Center\sgf2019\Papers\A_Combined_Waterfall_and_Swimmer_Plot\Image;
%let dpi=300;

proc format;
  value res
    0='1.0 mg'
	1='2.0 mg'
	2='3.0 mg'
	3='4.0 mg'
	4='3.0 F6 mg'
	5='4.0 F6 mg';
run;

/*--Create some data--*/
data tumor;
  label dropped='Discontinued' Duration='Treatment Duration';
  format Drug res.;
  length Code $6;
  do i=1 to 20;
    Response=100*(ranuni(3)-0.7);
    Duration=50*ranuni(3);
	Dropped=.;
    if ranuni(3) > 0.6 then Dropped=duration-5; 
	Drug=floor(6*ranuni(3));
	if ranuni(3) > 0.7 then Code='FL';
	else Code='DLBCL';
	codeloc=ifn(response > 0, 0, response);
	baseline=20+180*(ranuni(2));
    output;
  end;
run;

/*--Sort by descending response--*/
proc sort data=tumor out=tumor;
  by descending Response;
run;

data tumorsorted;
  set tumor;
  j=_n_;
run;

ods html;
proc print;run;
ods html close;

/*--Define Attributes map for walls and axes--*/
data attrmap;
  length ID $ 9 value $10 fillcolor $ 10 show $8;
  id='Resp';  value='1.0 mg';     fillcolor='white'; show='Attrmap'; output;
  id='Resp';  value='2.0 mg';     fillcolor='cxffffc0'; show='Attrmap'; output; 
  id='Resp';  value='3.0 mg';     fillcolor='cxf0d0a0'; show='Attrmap'; output;
  id='Resp';  value='4.0 mg';     fillcolor='orange'; show='Attrmap'; output; 
  id='Resp';  value='3.0 F6 mg';  fillcolor='cxff7f00'; show='Attrmap'; output; 
  id='Resp';  value='4.0 F6 mg';  fillcolor='red'; show='Attrmap'; output; 
run;

ods _all_ close;
ods listing gpath="&gpath" image_dpi=&dpi;

/*--2D Tumor Response and Duration Graph--*/
title 'Tumor Response and Duration by Subject Id';
footnote j=l h=7pt italic 'This graph uses simulated data for illustration only';
ods graphics / reset attrpriority=color width=4in height=3in imagename="WaterFall_Only";
proc sgplot data=tumorsorted noautolegend dattrmap=attrmap;
  styleattrs axisextent=data;
  band x=j upper=20 lower=-30 / fillattrs=(color=gold transparency=0.8);
  vbarparm category=j response=response / group=drug dataskin=pressed name='r' attrid=Resp;
  text x=j y=codeloc text=code / rotate=90 position=left textattrs=(size=6) contributeoffsets=(ymin);
  yaxis labelpos=datacenter grid display=(noline noticks) label='Change from Baseline (%)' labelattrs=(size=8);
  xaxis display=none type=discrete;
  keylegend 'r' / position=bottomleft location=inside across=1 valueattrs=(size=4) noborder;
run;

/*--2D Tumor Response and Duration Graph--*/
title 'Tumor Response and Duration by Subject Id';
footnote j=l h=7pt italic 'This graph uses simulated data for illustration only';
ods graphics / reset attrpriority=color width=4in height=3in imagename="WaterFall_With_Duration_SG";
proc sgplot data=tumorsorted noautolegend dattrmap=attrmap;
  styleattrs axisextent=data;
  vbarparm category=j response=duration / fillattrs=graphdata1 dataskin=pressed y2axis name='d';
  vbarparm category=j response=response / group=drug dataskin=pressed name='r' attrid=Resp;
  scatter x=j y=dropped / y2axis markerattrs=(symbol=diamondfilled size=5)
          filledoutlinedmarkers markerfillattrs=(color=gold) name='c';
  text x=j y=codeloc text=code / rotate=90 position=left textattrs=(size=6) contributeoffsets=(ymin);
  yaxis offsetmax=0.5 labelpos=datacenter grid display=(noline noticks) label='Change from Baseline (%)' labelattrs=(size=8);
  y2axis offsetmin=0.55 labelpos=datacenter grid display=(noline noticks) labelattrs=(size=8);
  xaxis display=none colorbands=odd colorbandsattrs=(transparency=0.3);
  keylegend 'r' / position=bottomleft location=inside across=2 valueattrs=(size=4) noborder;
  keylegend 'c' / position=topright location=inside  valueattrs=(size=6) noborder;
run;

/*--Define Template for graph--*/
proc template;
  define statgraph Waterfall_Plus;
    begingraph / axislineextent=data;
	  entrytitle 'Tumor Response and Duration by Subject Id';
	  entryfootnote halign=left 'This graph uses simulated data for illustration only' / 
                    textattrs=(size=7pt style=italic);
	  layout lattice / columndatarange=union rowweights=(0.45 0.55) rowgutter=0;
	    columnaxes;
		  columnaxis / display=none discreteopts=(colorbands=odd colorbandsattrs=(transparency=0.2));
		endcolumnaxes;
	    layout overlay / yaxisopts=(griddisplay=on offsetmax=0.1 tickvalueattrs=(size=6) labelattrs=(size=8)) 
                                    walldisplay=none;
		  barchartparm category=j response=duration / datalabel=duration 
                       fillattrs=graphdata1 datalabelattrs=(size=5)
                       dataskin=pressed displaybaseline=auto;
          scatterplot x=j y=dropped / markerattrs=(symbol=diamondfilled size=9)
                      filledoutlinedmarkers=true markerfillattrs=(color=gold)
                      markeroutlineattrs=(color=black) name='d' legendlabel='Discontinued';
	      discretelegend 'd' / location=inside valign=top halign=left valueattrs=(size=7) 
                      border=false autoitemsize=true;
		endlayout;
	    layout overlay / yaxisopts=(griddisplay=on tickvalueattrs=(size=6) labelattrs=(size=8) offsetmax=0 
                                    linearopts=(tickvaluepriority=true) label='Change from Baseline (%)')
                                    walldisplay=none;
		  bandplot x=j limitupper=20 limitlower=-30 / extend=true fillattrs=(color=gold transparency=0.75);
          barchartparm category=j response=response / group=drug groupdisplay=cluster
                       datalabelattrs=(size=5) dataskin=pressed name='a' datalabelfitpolicy=rotate;
          textplot x=j y=codeloc text=code / rotate=90 position=left textattrs=(size=6) contributeoffsets=(ymin);
	      discretelegend 'a' / location=inside valign=bottom halign=left order=columnmajor down=3 opaque=true
                         valueattrs=(size=5) border=false;
		endlayout;
	  endlayout;
	endgraph;
  end;
run;

ods graphics / reset width=4in height=3in imagename='Waterfall_With_Duration_GTL';
proc sgrender template=Waterfall_Plus data=tumorsorted dattrmap=attrmap;
format duration 3.0;
dattrvar drug="Resp";
run;

