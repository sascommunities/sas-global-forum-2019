options cmplib=sasuser.funcs;
%let gpath=\\sashq\root\dept\dvr\DVR_Knowledge_Center\sgf2019\Papers\A_Combined_Waterfall_and_Swimmer_Plot\Image;
%let dpi=300;

options mautosource mprint mlogic;
ods html close;

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
/*data tumor;*/
/*  format Drug res.;*/
/*  length Code $6;*/
/*  drop i;*/
/*  do i=1 to 20;*/
/*    Response=100*(ranuni(3)-0.7);*/
/*    Duration=50*ranuni(3);*/
/*	Dropped=0;*/
/*    if ranuni(3) > 0.6 then Dropped=1; */
/*	Drug=floor(6*ranuni(3));*/
/*	if ranuni(3) > 0.7 then Code='FL';*/
/*	else Code='DLBCL';*/
/*    output;*/
/*  end;*/
/*run;*/

/*--Create some data--*/
data tumor;
  format Drug res.;
  length Code $6;
  do i=1 to 20;
    Response=100*(ranuni(3)-0.7);
    Duration=50*ranuni(3);
	Dropped=.;
    if ranuni(3) > 0.8 then Dropped=duration-5; 
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

/*ods html;*/
/*proc print;*/
/*var j drug code response duration dropped codeloc baseline;*/
/*run;*/
/*ods html close;*/

ods _all_ close;
ods listing gpath="&gpath" image_dpi=&dpi;

/*--Define Attributes map for walls and axes and Drug Group Colors--*/
data attrmap;
  length ID $ 9 value $10 fillcolor $ 10 linecolor $ 10 linepattern $ 10 show $8;
  id='Walls'; value='Center'; fillcolor='cxd0d0d0'; linecolor='cxd0d0d0'; linepattern='Solid'; output;
  id='Walls'; value='Back';   fillcolor='cxe0e0e0'; linecolor='cxe0e0e0'; linepattern='Solid'; output;
  id='Walls'; value='Right';  fillcolor='cxf0f0f0'; linecolor='cxf0f0f0'; linepattern='Solid'; output;
  id='Walls'; value='Bottom'; fillcolor='cxe7e7e7'; linecolor='cxe7e7e7'; linepattern='Solid'; output;
  id='Axes';  value='D';      fillcolor='white'; linecolor='black'; linepattern='Solid'; output;
  id='Axes';  value='L';      fillcolor='white'; linecolor='black'; linepattern='ShortDash'; output;

  /*--Change only the values below this for Treatment Group--*/
  id='Resp';  value='1.0 mg';     fillcolor='white'; show='Attrmap'; output;
  id='Resp';  value='2.0 mg';     fillcolor='cxffffc0'; show='Attrmap'; output; 
  id='Resp';  value='3.0 mg';     fillcolor='cxf0d0a0'; show='Attrmap'; output;
  id='Resp';  value='4.0 mg';     fillcolor='orange'; show='Attrmap'; output; 
  id='Resp';  value='3.0 F6 mg';  fillcolor='cxff7f00'; show='Attrmap'; output; 
  id='Resp';  value='4.0 F6 mg';  fillcolor='red'; show='Attrmap'; output; 
run;

/*proc print;run;*/
/*ods html;*/
ods graphics / reset attrpriority=color width=4in height=4in imagename="Waterfall_Xf_100";
%WaterFall_3D_Macro (Data=tumor, Duration=Duration, Response=response, Dropped=dropped, Group=Drug, Code=Code,
          AttrMap=attrmap, Lblx=Subject, Lbly=Duration of Treatment in Days, Lblz=Tumor Lesion Best Change, 
          xFac=1.0, Tilt=75, Rotate=-45, Title=Tumor Response and Duration);

ods graphics / reset attrpriority=color width=4in height=4in imagename="Waterfall_Xf_125";
%WaterFall_3D_Macro (Data=tumor, Duration=Duration, Response=response, Dropped=dropped, Group=Drug, Code=Code,
          AttrMap=attrmap, Lblx=Subject, Lbly=Duration of Treatment in Days, Lblz=Tumor Lesion Best Change, 
          xFac=1.25, Tilt=75, Rotate=-45, Title=Tumor Response and Duration);

ods graphics / reset attrpriority=color width=4in height=4in imagename="Waterfall_Xf_150";
%WaterFall_3D_Macro (Data=tumor, Duration=Duration, Response=response, Dropped=dropped, Group=Drug, Code=Code,
          AttrMap=attrmap, Lblx=Subject, Lbly=Duration of Treatment in Days, Lblz=Tumor Lesion Best Change, 
          xFac=1.5, Tilt=75, Rotate=-45, Title=Tumor Response and Duration);

/*ods html close;*/

/*ods graphics / reset attrpriority=color width=4in height=4in imagename="Waterfall_075";*/
/*%WaterFall_3D_Macro (Data=tumor, Duration=duration, Response=response, Dropped=dropped, Group=Drug, Code=Code,*/
/*          AttrMap=attrmap, Lblx=Subject, Lbly=Duration of Treatment in Days, Lblz=Tumor Lesion Best Change, */
/*          xFac=0.75, Tilt=75, Rotate=-45, Title=Tumor Response and Duration);*/
/**/
/*ods graphics / reset attrpriority=color width=4in height=4in imagename="Waterfall_100";*/
/*%WaterFall_3D_Macro (Data=tumor, Duration=duration, Response=response, Dropped=dropped, Group=Drug, Code=Code,*/
/*          AttrMap=attrmap, Lblx=Subject, Lbly=Duration of Treatment in Days, Lblz=Tumor Lesion Best Change,*/
/*          xFac=1.0, Tilt=75, Rotate=-45, Title=Tumor Response and Duration);*/
/**/
/*ods graphics / reset attrpriority=color width=4in height=4in imagename="Waterfall_150";*/
/*%WaterFall_3D_Macro (Data=tumor, Duration=duration, Response=response, Dropped=dropped, Group=Drug, Code=Code,*/
/*          AttrMap=attrmap, Lblx=Subject, Lbly=Duration of Treatment in Days, Lblz=Tumor Lesion Best Change, */
/*          xFac=1.5, Tilt=75, Rotate=-45, Title=Tumor Response and Duration);*/
/**/
/*ods graphics / reset attrpriority=color width=4in height=4in imagename="Waterfall_200";*/
/*%WaterFall_3D_Macro (Data=tumor, Duration=duration, Response=response, Dropped=dropped, Group=Drug, Code=Code,*/
/*          AttrMap=attrmap, Lblx=Subject, Lbly=Duration of Treatment in Days, Lblz=Tumor Lesion Best Change, */
/*          xFac=2, Tilt=75, Rotate=-45, Title=Tumor Response and Duration);*/



