/*--------------------------------------------------------------------------------------------
  Please be aware that as a matter of policy, R&D is not able to provide programming services 
  or consulting services for SAS customers.  However, there are times when a coding example can 
  be of general use to customers and we can justify writing an example to demonstrate the type 
  of method or logic needed.  This program is for demonstration purpose only, and may work ONLY 
  for the combination of variables and data provided.  We cannot directly write a customer 
  program nor can we support or maintain the example program.  If there are further data changes 
  or requirements it will be up to you to make the necessary changes to the program to best 
  fit your data.
---------------------------------------------------------------------------------------------*/

options cmplib=sasuser.funcs;

%macro WaterFall_3D_Macro (
       Data=, 		/*--Required - Data set name--*/
       Duration=,	/*--Required - Treatment Duration variable--*/ 
       Response=, 	/*--Required - Tumor Response variable--*/
       Dropped=, 	/*--Required - Subjects dropped--*/
       Group=,		/*--Required - Treatment Drug--*/ 
       Code=, 		/*--Required - RECIST Code--*/
       AttrMap=,	/*--Required - Attribute Map--*/ 
       Lblx=X, 		/*--X-Axis (Front) Label--*/
       Lbly=Y,		/*--Y-Axis (Horizontal plane) Label--*/ 
       Lblz=Z,		/*--Z-Axis (Vertical) Label--*/ 
       xFac=1,		/*--X-Axis scale factor--*/ 
       Tilt=65,		/*--View Tilt 60 to 80--*/ 
       Rotate=-55,	/*--View Rotation -15 to -75--*/ 
       Title=		/*--Graph Title--*/
);

/*--Check for Required Parameters   --*/
/*--Terminate if these required parameters are not supplied--*/
%if %length(&Data) eq 0 %then %do;
%put The parameter 'Data' is required - WaterFall 3D Macro Terminated.;
%goto finished;
%end;

%if %length(&Duration) eq 0 %then %do;
%put The parameter 'Duration' is required - WaterFall 3D Macro Terminated.;
%goto finished;
%end;

%if %length(&Response) eq 0 %then %do;
%put The parameter 'Response' is required - WaterFall 3D Macro Terminated.;
%goto finished;
%end;

%if %length(&Dropped) eq 0 %then %do;
%put The parameter 'Dropped' is required - WaterFall 3D Macro Terminated.;
%goto finished;
%end;

%if %length(&Group) eq 0 %then %do;
%put The parameter 'Group' is required - WaterFall 3D Macro Terminated.;
%goto finished;
%end;

%if %length(&Code) eq 0 %then %do;
%put The parameter 'Code' is required - WaterFall 3D Macro Terminated.;
%goto finished;
%end;

%if &xFac > 4 %then %let xFac=4;
%if &xFac < 0.5 %then %let xFac=0.5;

%let A=&Tilt;
%if &Tilt > 80 %then %let A=80;
%if &Tilt < 60 %then %let A=60;

%let B=0;

%let C=&Rotate;
%if &Rotate > -15 %then %let C=-15;
%if &Rotate < -75 %then %let C=-75;

/*--Define walls and axes in the unit space including xFac for stretching the x-axis--*/
data Wall_Axes;
  length id $8 wgroup $1;
  dx=&xFac;
  id='X1-Axis'; wgroup='D'; xw=-dx; yw=-1; zw=-1; xw2= dx; yw2=-1; zw2=-1; xl=0; yl=-1; zl=-1.1; label=1; output;
  id='X3-Axis'; wgroup='L'; xw=-dx; yw=-1; zw= 1; xw2= dx; yw2=-1; zw2= 1; xl=.; yl= .; zl= .;   label=.; output;
  id='X4-Axis'; wgroup='D'; xw=-dx; yw= 1; zw= 1; xw2= dx; yw2= 1; zw2= 1; xl=.; yl= .; zl= .;   label=.; output;
  id='Y2-Axis'; wgroup='D'; xw=-dx; yw=-1; zw= 1; xw2=-dx; yw2= 1; zw2= 1; xl=.; yl= .; zl= .;   label=.; output;
  id='Y3-Axis'; wgroup='D'; xw= dx; yw=-1; zw=-1; xw2= dx; yw2= 1; zw2=-1; xl=dx+0.1; yl= 0; zl=-0.1; label=2; output;
  id='Y4-Axis'; wgroup='L'; xw= dx; yw=-1; zw= 1; xw2= dx; yw2= 1; zw2= 1; xl=.; yl=.; zl=.;   label=.; output;
  id='Z1-Axis'; wgroup='D'; xw=-dx; yw=-1; zw=-1; xw2=-dx; yw2=-1; zw2= 1; xl=-dx; yl=-1.2; zl=0;  label=3; output;
  id='Z2-Axis'; wgroup='L'; xw= dx; yw=-1; zw=-1; xw2= dx; yw2=-1; zw2= 1; xl=.; yl= .; zl= .;   label=.; output;
  id='Z4-Axis'; wgroup='D'; xw= dx; yw= 1; zw=-1; xw2= dx; yw2= 1; zw2= 1; xl=.; yl= .; zl= .;   label=.; output;
  call missing(xw2, yw2, zw2, xl, yl, zl, label);
  id='Back';   wgroup='D'; xw=-dx; yw=-1; zw=-1; output;
  id='Back';   wgroup='D'; xw=-dx; yw= 1; zw=-1; output;
  id='Back';   wgroup='D'; xw=-dx; yw= 1; zw= 1; output;
  id='Back';   wgroup='D'; xw=-dx; yw=-1; zw= 1; output;
  id='Right';  wgroup='D'; xw=-dx; yw= 1; zw=-1; output;
  id='Right';  wgroup='D'; xw= dx; yw= 1; zw=-1; output;
  id='Right';  wgroup='D'; xw= dx; yw= 1; zw= 1; output;
  id='Right';  wgroup='D'; xw=-dx; yw= 1; zw= 1; output;
  id='Bottom'; wgroup='D'; xw=-dx; yw=-1; zw=-1; output;
  id='Bottom'; wgroup='D'; xw= dx; yw=-1; zw=-1; output;
  id='Bottom'; wgroup='D'; xw= dx; yw= 1; zw=-1; output;
  id='Bottom'; wgroup='D'; xw=-dx; yw= 1; zw=-1; output;
  id='Center'; wgroup='D'; xw=-dx; yw=-1; zw=-0; output;
  id='Center'; wgroup='D'; xw= dx; yw=-1; zw=-0; output;
  id='Center'; wgroup='D'; xw= dx; yw= 1; zw=-0; output;
  id='Center'; wgroup='D'; xw=-dx; yw= 1; zw=-0; output;
run;

/*--Project the walls and axes--*/
data projected_walls;
  keep id wgroup xw yw zw xw2 yw2 zw2 xl yl zl lbx lby lbz label;
  array u[4,4]  _temporary_;  /*--Intermediate Matrix--*/
  array v[4,4]  _temporary_;  /*--Intermediate Matrix--*/
  array w[4,4]  _temporary_;  /*--Final View Matrix--*/
  array m[4,4]  _temporary_;  /*--Projection Matrix--*/
  array rx[4,4] _temporary_;  /*--X rotation Matrix--*/
  array ry[4,4] _temporary_;  /*--Y rotation Matrix--*/
  array rz[4,4] _temporary_;  /*--Z rotation Matrix--*/
  array d[4,1]  _temporary_;  /*--World Data Array --*/
  array p[4,1]  _temporary_;  /*--Projected Data Array --*/
  retain r t f n;
  r=1; t=1; f=1; n=-1;
  pi=constant("PI");
  fac=pi/180;
  A=&A*fac; B=&B*fac; C=&C*fac;

  /*--Set up projection matrix--*/
  m[1,1]=1/r;   m[1,2]=0.0;  m[1,3]=0.0;      m[1,4]=0.0;
  m[2,1]=0.0;   m[2,2]=1/t;  m[2,3]=0.0;      m[2,4]=0.0;
  m[3,1]=0.0;   m[3,2]=0.0;  m[3,3]=-2/(f-n); m[3,4]=-(f+n)/(f-n);
  m[4,1]=0.0;   m[4,2]=0.0;  m[4,3]=0.0;      m[4,4]=1.0;

  /*--Set up X rotation matrix--*/
  rx[1,1]=1;     rx[1,2]=0.0;     rx[1,3]=0.0;      rx[1,4]=0.0;
  rx[2,1]=0.0;   rx[2,2]=cos(A);  rx[2,3]=-sin(A);  rx[2,4]=0.0;
  rx[3,1]=0.0;   rx[3,2]=sin(A);  rx[3,3]=cos(A);   rx[3,4]=0.0;
  rx[4,1]=0.0;   rx[4,2]=0.0;     rx[4,3]=0.0;      rx[4,4]=1.0;

  /*--Set up Y rotation matrix--*/
  ry[1,1]=cos(B);  ry[1,2]=0.0;  ry[1,3]=sin(B);  ry[1,4]=0.0;
  ry[2,1]=0.0;     ry[2,2]=1.0;  ry[2,3]=0.0;     ry[2,4]=0.0;
  ry[3,1]=-sin(B); ry[3,2]=0.0;  ry[3,3]=cos(B);  ry[3,4]=0.0;
  ry[4,1]=0.0;     ry[4,2]=0.0;  ry[4,3]=0.0;     ry[4,4]=1.0;

  /*--Set up Z rotation matrix--*/
  rz[1,1]=cos(C);  rz[1,2]=-sin(C); rz[1,3]=0.0;  rz[1,4]=0.0;
  rz[2,1]=sin(C);  rz[2,2]=cos(C);  rz[2,3]=0.0;  rz[2,4]=0.0;
  rz[3,1]=0.0;     rz[3,2]=0.0;     rz[3,3]=1.0;  rz[3,4]=0.0;
  rz[4,1]=0.0;     rz[4,2]=0.0;     rz[4,3]=0.0;  rz[4,4]=1.0;
  
  /*--Build transform matris--*/
  call MatMult(rz, m, u);
  call MatMult(ry, u, v);
  call MatMult(rx, v, w);

  set Wall_Axes;

  /*--Set axis labels--*/
  if label eq 1 then lbx="&Lblx";
  if label eq 2 then lby="&Lbly";
  if label eq 3 then lbz="&Lblz";

  /*--Transform walls--*/
  d[1,1]=xw; d[2,1]=yw; d[3,1]=zw; d[4,1]=1;
  call MatMult(w, d, p);
  xw=p[1,1]; yw=p[2,1]; zw=p[3,1];

  /*--Transform axes--*/
  d[1,1]=xw2; d[2,1]=yw2; d[3,1]=zw2; d[4,1]=1;
  call MatMult(w, d, p);
  xw2=p[1,1]; yw2=p[2,1]; zw2=p[3,1];

  /*--Transform labels--*/
  d[1,1]=xl; d[2,1]=yl; d[3,1]=zl; d[4,1]=1;
  call MatMult(w, d, p);
  xl=p[1,1]; yl=p[2,1]; zl=p[3,1];
run;

/*--Compute slope of X & Y axes after transformation for label angle--*/
data _null_;
  fac=sqrt(&xFac);
  set projected_walls;
  dx=xw2-xw;
  if id='X1-Axis' then do;
	if abs(dx) > 0.001 then xaxisRot=fac*180*atan((yw2-yw)/dx)/3.1415;
	else xaxisRot=90;
	call symput ("xaxisRot", xaxisRot);
  end;
  if id='Y3-Axis' then do;
	if abs(dx) > 0.001 then yaxisRot=fac*180*atan((yw2-yw)/dx)/3.1415;
	else yaxisRot=90;
	 call symput ("yaxisRot", yaxisRot);
  end;
run;

/*--Find min & max for Duration and Response--*/
data _null_;
  retain durmin 1e6 durmax -1e6 resmin 1e6 resmax -1e6;
  set &Data end=last;

  durmin=min(durmin, &Duration);
  durmax=max(durmax, &Duration);

  resmin=min(resmin, &Response);
  resmax=max(resmax, &Response);

  if last then do;
    call symput ("DurMin", durmin);
	call symput ("DurMax", durmax);
    call symput ("ResMin", resmin);
	call symput ("ResMax", resmax);
  end;
run;

/*--Create all data from input waterfall data (not in unit coordinates)--*/
data polygons;
  retain pid 0 maxy -1e6 miny 1e6 maxz -1e6 minz 1e6;
  set &Data end=last;

  durfac=1.05;
  resfac=1.05;
  dx=&xFac;
  i=_n_-1;

  /*--Max range for Duration and Response--*/
  aResMax=resfac*max(abs(&ResMax), abs(&ResMin));
  aDurMax=durfac*max(abs(&DurMax), abs(&DurMin));

  /*--Create bars in z=0 plane for Duration--*/
  Lid=.;

  type='Duration';
  pid+1;
  z=0;

  x=dx*(i-0.5-0.4); y=0; output;
  x=x;              y=&Duration; output;
  x=dx*(i-0.5+0.4); y=y; output;
  x=x;              y=0; output;

  /*--Create bars in y=0 plane for Response--*/
  type='Response';
  pid+1;
  y=0;

  x=dx*(i-0.5-0.4); z=0; output;
  x=x;              z=&Response; output;
  x=dx*(i-0.5+0.4); z=z; output;
  x=x;              z=0; output;

  /*--Create diamond polygons for dropped subjects--*/
  if Dropped then do;
    pid+1;
    z=0;

    type='Dropped';
    x=dx*(i-0.5-0.3); y=&Duration-0.03*&DurMax; output;
    x=dx*(i-0.5);     y=&Duration; output;
    x=dx*(i-0.5+0.3); y=&Duration-0.03*&DurMax; output;
    x=dx*(i-0.5);     y=&Duration-0.06*&DurMax; output;
  end;

  /*--Save XMax value for bars--*/
  xMax=dx*(i);

  /*--Create code locations--*/
  type='Code';
  x=dx*(i-0.5); 
  z=ifn(&Response < 0, &Response, 0);
  y=0;
  output;

  /*--Create two more polygons to set aspect--*/
  if last then do;
    call missing (&duration, &response, &Code);
	type='Response';
    pid+1;
    x=-dx; y=0; z=-aResMax; output;
    x=-dx; y=0; z= aResMax; output;

    pid+1;
	type='Duration';
    x=-dx; y=0;       z=aResMax; output;
    x=-dx; y=aDurMax; z=aResMax; output;

    /*--Create Y axis (Duration) grid--*/
	pid=.;
    type='Y-Axis';
	Lid=1;
	z=0;
    do y=0 to aDurMax by 10;
	  x=-dx; output;
      x=xMax; output;
	  Lid+1;
	end;

    /*--Create Y axis (Duration) tick values--*/
    type='Y-Values';
	Lid=.;
	z=0;
    do y=0 to aDurMax by 10;
      x=xMax; 
	  yTickVal=y;
	  output;
	end;

    /*--Create Z axis (Vertical Response) tick values--*/
    type='Z-Values';
	yTickVal=.;
	Lid=.;
	y=0;
	x=dx*(-1);
    do z=-10 to -aResMax by -10;
	  zTickVal=z;
	  output;
	end;
    do z=0 to aResMax by 10;
	  zTickVal=z;
	  output;
	end;
  end;
run;

/*ods html;*/
/*proc print data=polygons;*/
/*var type pid x y z code Lid yTickVal zTickVal;*/
/*run;*/
/*ods html close;*/

/*--Compute data ranges--*/
data _null_;
  retain xmin 1e10 xmax -1e10 ymin 1e10 ymax -1e10 zmin 1e10 zmax -1e10;
  set polygons end=last;
  xmin=min(xmin, x);
  xmax=max(xmax, x);
  ymin=min(ymin, y);
  ymax=max(ymax, y);
  zmin=min(zmin, z);
  zmax=max(zmax, z);
  if last then do;
    call symput("xmin", xmin); call symput("xmax", xmax);
	call symput("ymin", ymin); call symput("ymax", ymax);
	call symput("zmin", zmin); call symput("zmax", zmax);
  end;
run;

/*%put "xmin=&xmin xmax=&xmax ymin=&ymin ymax=&ymax zmin=&zmin zmax=&zmax";*/


/*--Normalize the data to -1 to +1 ranges with xFac for stretching in x direction--*/
data normalized;
  keep &Group pid type x y z code Lid YTickVal zTickVal;
  xrange=&xmax-&xmin;
  yrange=&ymax-&ymin;
  zrange=&zmax-&zmin;
  set polygons;

  /*--data points--*/
  x=2*&xFac *(x-&xmin)/xrange -&xFac;
  y=2*(y-&ymin)/yrange -1;
  z=2*(z-&zmin)/zrange -1;
run;

/*ods html;*/
/*proc print data=normalized;run;*/
/*ods html close;*/

/*--Project the data--*/
data projected_data;
  keep  &Group pid type xd yd zd xr yr zr xc yc zc code xcode ycode zcode
        Lid xAy yAy zAy xAz yAz zAz xYv yYv yTickVal xZv yZv zTickVal;
  array u[4,4] _temporary_;  /*--Intermediate Matrix--*/
  array v[4,4] _temporary_;  /*--Intermediate Matrix--*/
  array w[4,4] _temporary_;  /*--Final View Matrix--*/
  array m[4,4] _temporary_;  /*--Projection Matrix--*/
  array rx[4,4] _temporary_; /*--X rotation Matrix--*/
  array ry[4,4] _temporary_; /*--Y rotation Matrix--*/
  array rz[4,4] _temporary_; /*--Z rotation Matrix--*/
  array d[4,1] _temporary_;  /*--World Data Array --*/
  array p[4,1] _temporary_;  /*--Projected Data Array --*/
  retain r t f n;
  r=1; t=1; f=1; n=-1;
  pi=constant("PI");
  fac=pi/180;

  A=&A*fac; B=&B*fac; C=&C*fac;

  /*--Set up projection matrix--*/
  m[1,1]=1/r;   m[1,2]=0.0;  m[1,3]=0.0;      m[1,4]=0.0;
  m[2,1]=0.0;   m[2,2]=1/t;  m[2,3]=0.0;      m[2,4]=0.0;
  m[3,1]=0.0;   m[3,2]=0.0;  m[3,3]=-2/(f-n); m[3,4]=-(f+n)/(f-n);
  m[4,1]=0.0;   m[4,2]=0.0;  m[4,3]=0.0;      m[4,4]=1.0;

  /*--Set up X rotation matrix--*/
  rx[1,1]=1;     rx[1,2]=0.0;     rx[1,3]=0.0;      rx[1,4]=0.0;
  rx[2,1]=0.0;   rx[2,2]=cos(A);  rx[2,3]=-sin(A);  rx[2,4]=0.0;
  rx[3,1]=0.0;   rx[3,2]=sin(A);  rx[3,3]=cos(A);   rx[3,4]=0.0;
  rx[4,1]=0.0;   rx[4,2]=0.0;     rx[4,3]=0.0;      rx[4,4]=1.0;

  /*--Set up Y rotation matrix--*/
  ry[1,1]=cos(B);  ry[1,2]=0.0;  ry[1,3]=sin(B);  ry[1,4]=0.0;
  ry[2,1]=0.0;     ry[2,2]=1.0;  ry[2,3]=0.0;     ry[2,4]=0.0;
  ry[3,1]=-sin(B); ry[3,2]=0.0;  ry[3,3]=cos(B);  ry[3,4]=0.0;
  ry[4,1]=0.0;     ry[4,2]=0.0;  ry[4,3]=0.0;     ry[4,4]=1.0;

  /*--Set up Z rotation matrix--*/
  rz[1,1]=cos(C);  rz[1,2]=-sin(C); rz[1,3]=0.0;  rz[1,4]=0.0;
  rz[2,1]=sin(C);  rz[2,2]=cos(C);  rz[2,3]=0.0;  rz[2,4]=0.0;
  rz[3,1]=0.0;     rz[3,2]=0.0;     rz[3,3]=1.0;  rz[3,4]=0.0;
  rz[4,1]=0.0;     rz[4,2]=0.0;     rz[4,3]=0.0;  rz[4,4]=1.0;
  
  /*--Build transform matris--*/
  call MatMult(rz, m, u);
  call MatMult(ry, u, v);
  call MatMult(rx, v, w);

  set normalized;

  /*--Transform coordinates--*/
  d[1,1]=x; d[2,1]=y; d[3,1]=z; d[4,1]=1;
  call MatMult(w, d, p);

  /*--extract data for Duration polygons--*/
  if type='Duration' then do;
    xd=p[1,1]; yd=p[2,1]; zd=p[3,1]; wd=p[4,1];
  end;

  /*--extract data for Response polygons--*/
  else if type='Response' then do;
    xr=p[1,1]; yr=p[2,1]; zr=p[3,1]; wr=p[4,1];
  end;

  /*--extract data for Dropped polygons--*/
  else if type='Dropped' then do;
    xc=p[1,1]; yc=p[2,1]; zc=p[3,1]; wc=p[4,1];
  end;

  /*--extract data for Code position--*/
  else if type='Code' then do;
    xcode=p[1,1]; ycode=p[2,1]; zcode=p[3,1]; wcode=p[4,1];
  end;

  /*--extract data for y-axis grid lines--*/
  else if type='Y-Axis' then do;
    xAy=p[1,1]; yAy=p[2,1]; zAy=p[3,1]; wAy=p[4,1];
  end;

  /*--extract data for y-axis tick values--*/
  else if type='Y-Values' then do;
    xYv=p[1,1]; yYv=p[2,1]; zYv=p[3,1]; wYv=p[4,1];
  end;

  /*--extract data for z-axis tick values--*/
  else if type='Z-Values' then do;
    xZv=p[1,1]; yZv=p[2,1]; zZv=p[3,1]; wZv=p[4,1];
  end;
run;
/**/
/*proc print data=projected_data;run;*/

/*--Combine data with walls--*/
data combined;
  merge projected_walls projected_data;
run;

/*proc print data=combined;*/
/*var type pid Lid xAy yAy zAy xZv yZv zTickVal;*/
/*run;*/
title;
/*--Draw the graph--*/
%if %length(&Title) > 0 %then %do;
title h=12pt "&Title";
%end;
footnote j=l  h=5pt italic "X-Rotation=&A  Y-Rotation=&B  Z-Rotation=&C";
proc sgplot data=combined nowall  noborder aspect=1 noautolegend dattrmap=&attrmap;
  /*--Walls and axis lines--*/
  polygon id=id x=xw y=yw / fill lineattrs=(color=lightgray) group=id transparency=0 attrid=walls;

  /*--Y-Axis gridlines--*/
  series x=xAy y=yAy / group=lid lineattrs=(color=cxb0b0b0 pattern=solid);

  /*--Duration Bars--*/
  polygon id=pid x=xd y=yd / fill outline dataskin=sheen fillattrs=graphdata1 name='D' legendlabel='Duration'
          lineattrs=(color=black);

  /*--Drop Markers--*/
  polygon id=pid x=xc y=yc / fill  dataskin=none fillattrs=(color=gold)  name='C' legendlabel='Drop';

  /*--Response Bars--*/
  polygon id=pid x=xr y=yr / fill outline  dataskin=none name='R' legendlabel='Response' 
          group=&Group lineattrs=(color=black) attrid=Resp dataskin=sheen;

  /*--Solid and dashed Axis Lines--*/
  vector x=xw2 y=yw2 / xorigin=xw yorigin=yw group=wgroup noarrowheads attrid=Axes;

  /*--Axis Labels--*/
  text x=xl y=yl text=lbx / position=bottomleft rotate=&xaxisRot textattrs=(size=5);
  text x=xl y=yl text=lby / position=bottom rotate=&yaxisRot textattrs=(size=5);
  text x=xl y=yl text=lbz / position=left rotate=90 position=top textattrs=(size=5);

  /*--Y-Axis tick values--*/
  text x=xYv y=yYv text=yTickVal / position=bottomright textattrs=(size=4);

  /*--Z-Axis tick values--*/
  text x=xZv y=yZv text=zTickVal / position=left textattrs=(size=4);
  scatter x=xZv y=yZv / markerattrs=(size=2 symbol=dot);

  /*--Code Labels--*/
  text x=xcode y=ycode text=code / position=left rotate=90 textattrs=(size=4);
/*  scatter x=xcode y=ycode / markerattrs=(size=3);*/

  keylegend 'R' 'C' / type=fillcolor title='CC-122' across=1 location=inside position=bottomright
             fillheight=5px fillaspect=1.5 titleattrs=(size=5) valueattrs=(size=5) opaque;

  xaxis display=none offsetmin=0.05 offsetmax=0.05;
  yaxis display=none offsetmin=0.05 offsetmax=0.05;

  run;
footnote;

%finished:
%mend WaterFall_3D_Macro;


