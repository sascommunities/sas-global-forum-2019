/*--------------------------------------------------------------------------
  The SAS programs and macros provided here assume you have a
  response variable Y and predictors X1, X2,..., X&dim, where the
  macro variable &dim is the number of continuous predictors.
  Before modifying these macros, you may want to run the macros
  with OPTIONS MPRINT to generate the text version of the programs.

  The four dedicated logistic regression procedures have
  computational differences that affect the way they are used.

  PROC LOGISTIC and PROC SURVEYLOGISTIC require 8 successful
  iterations of the optimizer before they try to identify
  separation.  If separation is detected or the iterations do not
  converge, then these two procedures stop the optimization and use
  the current set of parameter estimates for further processing.
  If you input a specific set of parameter estimates and specify
  MAXITER=0, then these procedures do not assess separation.

  PROC HPLOGISTIC and PROC LOGSELECT evaluate separation at every
  iteration, note it in their Convergence Status tables, but do not
  stop when separation is detected.  If the iterations do not
  converge, these procedures do not produce parameter estimates.
  If you input a specific set of parameter estimates and specify
  MAXITER=0, then these procedures assess separation.
  --------------------------------------------------------------------------*/


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  Macro variables for display and computational purposes
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/ 


%let defaultstyle=mystyle;
%global eqopts linegray;
%let eqopts = thresholdmin=0 thresholdmax=0 offsetmin=0.02 offsetmax=0.02;
%let eqopts = equatetype=equate xaxisopts=(&eqopts) yaxisopts=(&eqopts);
%let linegray= gray;
%let seed=3939; %let theta=pi/4; %let margin=0.2; %let n=50;


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  Macros for some common computations
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/ 


%macro makeRange(data=,dim=2); %local i;
   /*--------------------------------------------------------------------------
     Stores the range of the predictors X1, X2,... in macro variables
     named XMIN1, XMAX1, XMIN2, XMAX2,...

     data= names the input data set containing variables Y, X1, X2,...
     dim=  number of X-covariates 
     --------------------------------------------------------------------------*/ 
   proc means data=&data;
      var %do i=1 %to &dim; x&i %end;;
      output out=mout min=%do i=1 %to &dim; min&i %end;
                      max=%do i=1 %to &dim; max&i %end;; run;
   data _null_; set mout;
      %do i=1 %to &dim;
         %global xmin&i xmax&i;
         call symputx("xmin&i",min&i); call symputx("xmax&i",max&i);
      %end;
   run;
%mend;

%macro makeScore(data=,out=score,dim=2,gridsize=); %local i;
   /*--------------------------------------------------------------------------
     Outputs a SAS data set containing a grid of the predictors X1,
     X2,...  The grid is used for producing contour plots of the surfaces.
     Calls the makeRange macro.

     data=     names the input data set containing variables Y, X1, X2,...
     dim=      number of X-covariates 
     gridsize= size of the grid
     out=      data set containing the grid of values
     --------------------------------------------------------------------------*/ 
   %makeRange(data=&data,dim=&dim)
   %if NOT(&gridsize~=) %then %do;
      data _null_;
         set mout;
         %if %eval(&dim=2) %then %let gridsize=300;
         %else %if %eval(&dim=3) %then %let gridsize=200;
         %else %do; a=floor(10000000**(1/&dim));
                    %call %symputx("gridsize",a); %end;
      run;
   %end;
   data &out;
      %if %eval(&gridsize>0) %then %do;
         drop %do i=1 %to &dim; z&i %end;;
         %do i=1 %to &dim %by 1;
            do z&i= 0 to &gridsize;
               x&i= z&i/&gridsize*(&&xmax&i-&&xmin&i)+&&xmin&i;
         %end;
               output;
         %do i=1 %to &dim %by 1;
            end;
         %end;
      %end;
   run;
%mend;

%macro makeMaxMin(data=,est=,dim=); %local i;
   /*--------------------------------------------------------------------------
     Creates macro variables containing the range of the predicted
     probabilities for events, nonevents, and both: MINP0 MAXP0 MINP1 MAXP1 MINP MAXP;
     the ranges of linear predictors: MINXB0 MAXXB0 MINXB1 MAXXB1 MINXB MAXXB;
     and optionally the parameter estimates: BETA0 BETA1 BETA2,...
     and when &DIM=2 points and slopes for the dead-zone boundaries: M2N M2E SLOPEB

     data= name of the input data set containing variables Y, X1, X2,...
     dim=  number of X-covariates 
     est=  a TYPE=EST data set containing parameter estimates.
     --------------------------------------------------------------------------*/ 
   proc sort data=&data;
      by y;
   proc means data=&data(where=(y^=.));
      var p xbeta;
      by y;
      output out=mout min=min minxb max=max maxxb;
      run;
   data _null_;
      set mout end=eof;
      retain maxb minb 0 minp 1 maxp 0;
      %global maxp0 minp1 minp maxp maxxb0 minxb1 maxxb minxb;
      if (_n_=1) then do;
         minb=minxb;
         maxb=maxxb;
         minp=min;
         maxp=max;
         end;
      if y=0 then do;
         call symputx('maxp0',max);
         call symputx('maxxb0',maxxb);
         end;
      if y=1 then do;
         call symputx('minp1',min);
         call symputx('minxb1',minxb);
         end;
      minb=min(minb,minxb);
      maxb=max(maxb,maxxb);
      minp=min(minp,min);
      maxp=max(maxp,max);
      if (eof) then do; call symputx('maxp',maxp);
                        call symputx('maxxb',maxb);
                        call symputx('minp',minp);
                        call symputx('minxb',minb);
                        end;
   run;
   %if (&est~=) %then %do;
      data _null_; set &est;
         %global beta0; %do i=1 %to &dim; %global beta&i; %end;
         call symputx('beta0',Intercept);
         %do i=1 %to &dim; call symputx("beta&i",x&i); %end;
      run;
      %if (&dim=2) %then %do; /*compute the dead-zone boundaries*/
         data _null_; %global m2n m2e slopeb;
            x2nmin= ( &maxxb0 - &beta0 - &xmin1 * &beta1) / &beta2;
            call symputx('m2n',x2nmin);
            x2emin= ( &minxb1 - &beta0 - &xmin1 * &beta1) / &beta2;
            call symputx('m2e',x2emin);
            x2nmax= ( &maxxb0 - &beta0 - &xmax1 * &beta1) / &beta2;
            slopeb= (x2nmax-x2nmin)/(&xmax1-&xmin1);
            call symputx('slopeb',slopeb);
         run;
    %end; %end;
%mend;


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  INTRODUCTION
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/


/*--------------------------------------------------------------------------
  The Data1 data set contains a binary response variable Y and a
  single continuous predictor X1.  All nonevents (Y=0) are given an
  X1 value less than 0, and all events (Y=1) have an X1 value
  greater than 1.  The observations with a missing response value
  (Y=.) are added for drawing the fitted model.  The AGE variable
  takes values between 20 and 40 when X1<0, between 60 and 80 when
  X1>1, and between 40 and 60 otherwise.  The response variable is
  renamed RETIRED to indicate whether the individual has retired.
  Two frequency variables are also added; the F1 variable weighs
  the events more heavily and the F2 variable weighs the nonevents
  more.
  --------------------------------------------------------------------------*/
data Data1;
   do i=1 to &n;
      y=0;
      Retired=y;
      x1=ranuni(&seed)-1;
      Age= (x1+1)*20+20;
      f1=1;
      f2=1000;
      output;
      y=1;
      Retired=y;
      x1=ranuni(&seed)+1;
      Age= (x1-1)*20+60;
      f1=1000;
      f2=1;
      output;
   end;
   y=.;
   Retired=y;
   f1=.;
   f2=.;
   do x1=0 to 1 by 0.001;
      Age= x1*20+40;
      output;
   end;
run;

/*--------------------------------------------------------------------------
  A simple logistic regression of Retired on Age.
  Produces the Convergence Status table shown in Figure 2.
  --------------------------------------------------------------------------*/ 
proc logistic data=Data1;
   model Retired(event='1')=Age;
   output out=out p=p;
run;

/*--------------------------------------------------------------------------
  A simple logistic regression of Retired on Age with the
  NOCHECK option to suppress the separation checking.
  --------------------------------------------------------------------------*/
proc logistic data=Data1;
   model Retired(event='1')=Age / nocheck maxiter=100;
   output out=out2 p=p2;
run;

%macro data1Plot(freq=);
   /*--------------------------------------------------------------------------
     Displays the fitted curve for Retired regressed on Age.  The
     SGRENDER procedure is used throughout because it is more
     flexible than the SGPLOT procedure.

     freq=TRUE displays the fitted curve when nonevents have larger 
               frequencies and when events have larger frequencies
     freq=FALSE displays the default model with NOCHECK
     --------------------------------------------------------------------------*/
   data out;
      merge out out2;
   data out;
      set out;
      if (y^=.) then do;
         p=.;
         p2=.;
         end;
   proc template;
      define statgraph myTpl;
      begingraph / designheight=2.5in designwidth=6.5in drawspace=datavalue;
      layout overlay / yaxisopts=(label="Predicted Probability");
         lineparm x=50 y=1 slope=0 / curvelabel="Retired" curvelabellocation=outside
                                     curvelabelposition=max lineattrs=(thickness=0);
         lineparm x=50 y=0 slope=0 / curvelabel="Not Retired"  curvelabellocation=outside
                                     curvelabelposition=max lineattrs=(thickness=0);
         scatterplot x=Age y=Retired / markerattrs=GraphData1 primary=true datatransparency=0.5;
         drawtext "Events"    / x=60 y=.9 anchor=left width=20;
         drawtext "Nonevents" / x=40 y=.1 anchor=right width=20;
         %if (&freq~=) %then %do;
            seriesplot x=Age y=p2 / lineattrs=GraphData1;
            seriesplot x=Age y=pe / lineattrs=GraphData2;
            seriesplot x=Age y=pn / lineattrs=GraphData3;
            drawtext textattrs=GraphValueText(color=GraphData2:contrastcolor) "More events"
                   / x=48 y=.5 anchor=right width=100;
            drawtext textattrs=GraphValueText(color=GraphData3:contrastcolor) "More nonevents"
                   / x=52 y=.5 anchor=left  width=100;
         %end; %else %do;
            seriesplot x=Age y=p  / lineattrs=GraphData1;
            seriesplot x=Age y=p2 / lineattrs=GraphData2;
            dropline y=.47 x=49.81 / dropto=both;
            drawtext textattrs=GraphValueText(color=GraphData1:contrastcolor) "Default"
                   / x=51 y=.6 anchor=left width=50;
            drawtext textattrs=GraphValueText(color=GraphData2:contrastcolor) "Nocheck"
                   / x=50 y=.6 anchor=right width=50;
         %end;
      endlayout;
      endgraph;
      end;
   proc sgrender data=out template=myTpl; run;
%mend;

/*--------------------------------------------------------------------------
  Display Figure 1
  --------------------------------------------------------------------------*/
%data1plot


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  Should You Make Predictions Inside the Dead Zone?
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/


/*--------------------------------------------------------------------------
  Use the F1 variable in the Data1 data set to fit a model with more events.
  --------------------------------------------------------------------------*/
proc logistic data=Data1;
  model Retired(event='1')=Age / nocheck;
  freq f1;
  output out=oute p=pe;
run;

/*--------------------------------------------------------------------------
  Use the F2 variable in the Data1 data set to fit a model with more events.
  --------------------------------------------------------------------------*/
proc logistic data=Data1;
  model Retired(event='1')=Age / nocheck;
  freq f2;
  output out=outn p=pn;
run;

/*--------------------------------------------------------------------------
  Display Figure 3
  --------------------------------------------------------------------------*/
data out;
   merge out2 oute outn;
data out;
   set out;
   if (Retired^=.) then do;
      p=.;
      pe=.;
      pn=.;
      end;
run;
%data1Plot(freq=true)


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  MEASURING THE DEAD ZONE
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/


%macro measure(data=,model=x:,dim=2,n=1000,seed=3939,store=mymodel,out=out1);
   /*--------------------------------------------------------------------------
     Fits a logistic regression model to your data set.  Random points
     from the range of your data are chosen, PROC PLM scores the
     points, and PROC MEANS computes the proportion of observations in
     the Dead Zone along with a standard error and reports this as the
     Sample Proportion. The second part of this macro finds the margin
     of the Dead Zone and the maximum possible distance between any
     two observations, then reports the quotient as the Margin
     Proportion.  
     Calls the makeMaxMin and makeRange macros.
   
     data= name of the input data set containing variables Y, X1, X2,...
     model=right-hand-side of the model statement
     dim=  number of X-covariates 
     n=    number of samples to draw
     seed= starting seed value for the random number generator
     store=name the itemstore that contains the fitted model from PROC LOGISTIC to feed into PROC PLM
     out=  output data set containing the measures
     --------------------------------------------------------------------------*/
   ods listing close; options nonotes;
   proc logistic data=&data;
      model y(event='1')=&model;
      output out=out p=p xbeta=xbeta;
      store &store;
   %makeMaxMin(data=out,dim=&dim)
   %makeRange(data=&data,dim=&dim)
   data tmp;
      %do i=1 %to &n;
          %do j=1 %to &dim;
             z=ranuni(&seed);
             x&j=z*(&&xmax&j-&&xmin&j)+&&xmin&j;
          %end;
          y=.;
          output;
      %end;
   proc plm restore=&store;
      score data=tmp out=tmp / ilink;
   data tmp;
      set tmp;
      keep sp;
      sp=(Predicted>&maxp0 & Predicted<&minp1);
   proc means data=tmp;
      var sp;
      output out=mout mean=mean stderr=stderr n=n;
   data &out;
      set mout;
      keep Statistic Value StdError N;
      length Statistic $ 17;
      Statistic='Sample Proportion';
      Value=mean;
      StdError=stderr;
      N=n;
      output;
   data out2;
      keep Statistic Value StdError N;
      margin= abs(&minxb1-&maxxb0);
      range=  abs(&maxxb-&minxb);
      Statistic='Margin Proportion';
      Value= margin/range;
      StdError=.;
      N=.;
   data &out;
      set &out out2;
   ods listing; options notes;
   proc print data=&out noobs;
      var Statistic Value StdError N;
      format Value StdError best6.;
   run;
%mend;

/*--------------------------------------------------------------------------
  Display Figure 4
  --------------------------------------------------------------------------*/
%measure(data=Data1,dim=1,n=10000)


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  SEARCHING FOR THE DEAD ZONE
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/


/*--------------------------------------------------------------------------
  The Data2 data set is sampled from all but a diagonal slice through
  the X1-X2 plane.  
  --------------------------------------------------------------------------*/
data Data2; pi=constant("pi");
   theta=&theta;
   phi=pi/4;
   do i=1 to 100;
      done=0;
      do until(done=1);
         z1= rannor(&seed);
         z2= 0.75*rannor(&seed);
         if (z2<-&margin | z2>&margin) then done=1;
      end;
      y=(z2>0);
      x1= z1*cos(theta)-z2*sin(theta);
      x2= z1*sin(theta)+z2*cos(theta);
      output;
   end;
   px1=0;
   px2=0;
   x1=.;
   x2=.;
   y=.;
   output;
   drop done z1 z2 theta pi;
proc sort data=Data2;
   by y;
   run;

/*--------------------------------------------------------------------------
  Display Figure 5
  --------------------------------------------------------------------------*/
proc template;
   define statgraph myTpl;
   begingraph;
   layout overlayequated / &eqopts;
      scatterplot x=x1  y=x2  / markerattrs=GraphData1 primary=true;
      scatterplot x=px1 y=px2 / markerattrs=GraphData3(size=11 symbol=X weight=bold);
   endlayout;
   endgraph;
   end;
proc sgrender data=Data2 template=myTpl; run;

/*the X1 and Y1 macro variable columns help draw the designed dead-zone boundaries*/
data _null_;
   pi=constant("pi");
   theta=&theta;
   z1=0;
   z2=&margin;
   %global x1 y1;
   x1= z1*cos(theta)-z2*sin(theta);
   x2= z1*sin(theta)+z2*cos(theta);
   call symputx('x1',x1);
   call symputx('y1',x2);
run;

%macro data2Plot(data=out,contour=,boundary=,origin=);
   /*--------------------------------------------------------------------------
     Displays the Data2 data (events are red, nonevents are blue) and
     two gray diagonal lines that show where the designed Dead Zone
     is.  It optionally marks the origin, shades in the identified
     Dead Zone, and draws two green diagonal lines that emphasize its
     boundary.
   
     data=    names the input data set containing variables Y, X1, X2,...
     contour= shade the the discovered Dead Zone; requires S1, S2
     boundary=outline the discovered Dead Zone
     origin=  mark the location of the origin; requires PX1, PX2
     --------------------------------------------------------------------------*/
   proc template;
      define statgraph myTpl;
      begingraph / drawspace=datavalue ;
      layout overlayequated / &eqopts;
         %if (&contour~=) %then %do;
            contourplotparm x=s1 y=s2 z=sp / contourtype=gradient colormodel=TwoColorRamp;
         %end;
         lineparm x=&x1 y=&y1 slope=1 / lineattrs=(color=&linegray) clip=true;
         lineparm x=eval(-&x1) y=eval(-&y1) slope=1 / lineattrs=(color=&linegray) clip=true;
         %if (&boundary~=) %then %do;
            lineparm x=&xmin1 y=&m2n slope=&slopeb / lineattrs=GraphData3 clip=true;
            lineparm x=&xmin1 y=&m2e slope=&slopeb / lineattrs=GraphData3 clip=true;
         %end;
         scatterplot x=x1 y=x2 / group=y includemissinggroup=false primary=true;
         %if (&origin~=) %then %do;
            scatterplot x=px1 y=px2 / markerattrs=GraphData3(size=11 symbol=X weight=bold);
         %end;
         drawtext textattrs=(color=GraphData2:contrastcolor) "Events"
                / x=-2.2 y=-1.8 anchor=right width=20;
         drawtext textattrs=(color=GraphData1:contrastcolor) "Nonevents"
                / x=-1.4 y=-1.8 anchor=left width=20;
      endlayout;
      endgraph;
      end;
   proc sgrender data=&data template=myTpl;
   run;
%mend;

/*--------------------------------------------------------------------------
  Display Figure 6 and measure the Data2 data
  --------------------------------------------------------------------------*/
%data2Plot(data=Data2,origin=true)
%measure(data=Data2,n=10000)


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  Search Method 1: Using Predicted Probabilities from the Model
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/


%macro usePred(data=Data2,model=x:,dim=2,method=);
   /*--------------------------------------------------------------------------
     Fits a model using PROC LOGISTIC or PROC HPSVM, computes predicted
     probabilities across the range of data, and compares these to the
     pi_e and pi_n values to determine whether the observation lies
     inside the Dead Zone.  Observations that are in the Dead Zone set
     the indicator SP=1.  Results are stored in the OUT data set.
     Calls the makeMaxMin and makeRange macros.
     
     data=  input data set
     model= right-hand side of the MODEL statement
     dim=   number of continuous predictors
     method=SVM: use support vector machine, else use logistic regression
     --------------------------------------------------------------------------*/
   ods listing close; options nonotes;
   proc logistic data=&data outest=est;
      model y(event='1')=&model;
      output out=out p=p xbeta=xbeta;
      store mymodel;
   run;
   %if %eval(&method=svm) %then %do;
      proc hpsvm data=&data noscale;
         input &model / level=interval;
         target y / order=desc;
         id y &model;
         output out=out;
         code file="mycode";
      run;
      data out;
         set out;
         p=P_y1;
         if (p<1e-8) then p=1e-8;
         if (p>(1-1e-8)) then p=1-1e-8;
         xbeta=log(p/(1-p));
         run;
   %end;
   %makeMaxMin(data=out,est=est,dim=&dim)
   %makeScore(data=out,out=score,dim=&dim)
   %if %eval(&method=svm) %then %do;
      data out;
         set score;
         %inc "mycode"; Predicted=P_y1;
         run;
   %end;
   %else %do;
      proc plm restore=mymodel;
         score data=score out=out / ilink;
         run;
   %end;
   data out;
      set out;
      keep sp %do i=1 %to &dim; s&i %end;;
      sp=(Predicted>&maxp0 & Predicted<&minp1);
      %do i=1 %to &dim; s&i=x&i; %end;
   run;
   data out;
      set out &data;
      run;
   ods listing; options notes;
%mend;

/*--------------------------------------------------------------------------
  Display Figures 7 and 8
  --------------------------------------------------------------------------*/
%usePred(data=Data2)
%data2Plot(contour=true,boundary=true)

%usePred(data=Data2,method=svm)
%data2Plot(contour=true)


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  Search Method 2: A Random Walk through the (Expanded) Dead Zone
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/


/*--------------------------------------------------------------------------
  The Data2b data set samples Z1 and Z2 from the second and fourth
  quadrants, then rotates to get the X1-X2 coordinates.
  --------------------------------------------------------------------------*/
data Data2b;
   pi=constant("pi");
   theta=&theta;
   do i=1 to 100;
      done=0;
      do until(done=1);
         z1= rannor(&seed);
         z2= 0.75*rannor(&seed);
         if (z2<-&margin | z2>&margin) then do;
            if (z2>&margin & z1<-&margin) then done=1;
            else if (z2<-&margin & z1>&margin) then done=1;
         end;
      end;
      y=(z2>0);
      x1= z1*cos(theta)-z2*sin(theta);
      x2= z1*sin(theta)+z2*cos(theta);
      output;
   end;
   drop done z1 z2 theta;
proc sort data=Data2b;
   by y;
run;

%macro walk(data=Data2b,n=100,maxretry=100,seed=298512091,append=,dim=2);
   /*--------------------------------------------------------------------------
     Implements a random walk.  In particular, note that an INEST data
     set is used to input the candidate parameters, and PROC
     HPLOGISTIC is used with the MAXITER=0 option to score the data
     using the candidate parameters and to evaluate separation.  
     The OUT data set contains columns for displaying the results.
     The BOUNDS data set contains the parameters that define the
     separating surfaces and pi_n and pi_e for each surface.
     Calls the makeMaxMin and makeScore macros.
   
     data=     names the input data set
     dim=      number of continuous predictors
     n=        number of samples
     maxretry= number of times to retry obtaining a separating surface
     seed=     initial random number seed
     append=   append to existing OUT data set
     --------------------------------------------------------------------------*/
   ods listing close; options nonotes;
   data tmp;
      set &data score;
      run;
   proc logistic data=&data outest=est0;
      model y(event='1')=x: / tech=nr gconv=1e-12;
      output out=out0 p=p xbeta=xbeta;
   run;
   %makeMaxMin(data=out0,est=est0,dim=&dim)
   data bounds;
      %do j=0 %to &dim; x&j=&&beta&j; %end;
      maxp0=&maxp0;
      minp1=&minp1;
      run;
   %makeScore(data=&data,out=score)
   data est;
      set est0;
      run;
   %do i=1 %to &n;
      %let totretry=-1;
      %retry:
      %let totretry=%eval(&totretry+1);
      %if (%eval(100*(&i / 100) =&i)) %then %put &=i &totretry;
      %if (%eval(&totretry=&maxretry)) %then %goto done;
      data inest(type=EST);
         set est;
         seed=&seed;
         call streaminit(&seed);
         call ranuni(seed,eps);
         Intercept= Intercept+eps-0.5;
         %do j=1 %to &dim;
            call ranuni(seed,eps);
            x&j= x&j+eps-0.5;
         %end;
         call symputx('seed',seed);
      proc hplogistic data=tmp inest=inest maxiter=0;
         model y(event='1')=x:;
         ods output convergencestatus=cs;
         output out=out2 p=p xbeta=xbeta copyvars=(y %do j=1 %to &dim; x&j %end;);
      run;
      %let csep=0;
      data _null_;
         set cs;
         if (find(reason,'Complete')) then call symput('csep',1);
         run;
      %if %eval(&csep=0 | &sysrc^=0 | &syserr^=0) %then %put &=i &=csep &=sysrc &=syserr;;
      %if %eval(&csep=0)    %then %goto retry;
      %if %eval(&sysrc^=0)  %then %goto retry;
      %if %eval(&syserr^=0) %then %goto retry;
      %let badness=0;
      data _null_;
         set out2;
         if ((y=1 & p < 0.5) | (y=0 & p > 0.5)) then call symput('badness',1);
         run;
      %if %eval(&badness=1) %then %goto retry;
      data est(type=EST);
         set inest;
         run;
      data outs;
         set out2;
         if y^=.;
         run;
      %makeMaxMin(data=outs,est=est,dim=&dim)
      data outs;
         set out2;
         drop %do j=1 %to &dim; x&j %end;;
         if y=.;
         sp2=(p>&maxp0 & p<&minp1);
         %do j=1 %to &dim; s&j=x&j; %end;
         run;
      %if %eval(&i=1 & &append=) %then %do;
         data out;
            set outs;
            change=0;
            sp=sp2;
            drop sp2;
            run;
         data bounds;
            %do j=0 %to &dim; x&j=&&beta&j; %end;
            maxp0=&maxp0;
            minp1=&minp1;
            run;
      %end;
      %else %do;
         data out;
            merge out outs;
            drop sp2;
            if (sp2=1 & sp=0) then do;
               sp=1;
               change=&i;
               end;
         run;
         data bounds2;
            %do j=0 %to &dim; x&j=&&beta&j; %end;
            maxp0=&maxp0;
            minp1=&minp1;
         data bounds;
            set bounds bounds2;
            run;
      %end;
   %end;
   %done:
   data out;
      set out &data;
      run;
   ods listing; options notes;
   %let i=%eval(&i-1);
   %put Number of Samples is &i;
%mend;

%macro walkPlot;
   /*--------------------------------------------------------------------------
     Displays the results of the WALK macro on Data2b.  Displays
     the observed data (events are red, nonevents are blue),
     outlines the designed Dead Zone in gray, shades in the
     identified Dead Zone, and outlines the Dead Zone identified by
     the usePred macro in green.  
     Calls the makeMaxMin macro.
   
     data=     names the input data set
     dim=      number of continuous predictors
     n=        number of samples
     maxretry= number of times to retry obtaining a separating surface
     seed=     initial random number seed
     append=   append to existing OUT data set
     --------------------------------------------------------------------------*/
   %makeMaxMin(data=out0,est=est0,dim=2) /*computes the usePred boundary*/
   proc template;
      define statgraph myTpl;
      begingraph / designheight=3.7in drawspace=datavalue;
      layout overlayequated / &eqopts;
         contourplotparm x=s1 y=s2 z=sp / colormodel=twocolorramp contourtype=gradient;
         beginpolyline x=-1.82 y=-1.54 / lineattrs=GraphReference(color=&linegray);
            draw x=-.28 y=0; draw x=-1.44 y=1.15;
         endpolyline;
         beginpolyline x=1.82 y=-1.54 / lineattrs=GraphReference(color=&linegray);
            draw x=.28 y=0; draw x=1.44 y=1.15;
         endpolyline;
         lineparm x=&xmin1 y=&m2n slope=&slopeb / lineattrs=GraphData3 clip=true;
         lineparm x=&xmin1 y=&m2e slope=&slopeb / lineattrs=GraphData3 clip=true;
         scatterplot x=x1 y=x2 / group=y includemissinggroup=false primary=true;
         drawtext textattrs=(color=GraphData2:contrastcolor) "Events"
                / x=-2  y=-1.2 anchor=left width=20;
         drawtext textattrs=(color=GraphData1:contrastcolor) "Nonevents"
                / x=2.2 y=-1.2 anchor=right width=20;
         drawtext textattrs=(color=GraphData3:contrastcolor) "usePred"
                / x=.4 y=1.1 anchor=right width=20 rotate=87;
      endlayout;
      endgraph;
      end;
   run;
   proc sgrender data=out template=myTpl; run;
%mend;

%macro walkDeadZone(scoredata=,dim=2);
   /*--------------------------------------------------------------------------
     Determines which observations in an input data set are actually
     in the Dead Zone identified by the WALK macro.  Computing x'beta
     in a DATA step is computationally faster than scoring each model
     through PROC LOGISTIC.  Adds a DEADZONE indicator column to the
     SCOREDATA= data set that equals 1 when that observation is in the
     Dead Zone.
   
     scoredata= names the data set to be scored
     dim=       number of continuous predictors
     --------------------------------------------------------------------------*/
   data _null_;
      set bounds end=eof;
      if (eof) then call symput('lastbound',_n_);
      run;
   data &scoredata;
      set &scoredata;
      deadzone=0;
      run;
   ods listing close; options nonotes;
   %do i=1 %to &lastbound;
      data _null_;
         set bounds;
         if (&i=_n_);
         call symputx("minp1",minp1);
         call symputx("maxp0",maxp0);
         call symputx("beta0",x0);
         %do j=1 %to &dim; call symputx("beta&j",x&j); %end;
         run;
      data &scoredata;
         set &scoredata;
         drop xbeta p dz;
         if (deadzone=0) then do;
            xbeta=&beta0 %do j=1 %to &dim; + &&beta&j * x&j %end;;
            if (xbeta<0) then p=exp(xbeta)/(1+exp(xbeta));
            else p=1/(1+exp(-xbeta));
            dz= (p>&maxp0 & p<&minp1);
            deadzone = max(deadzone,dz);
         end;
      run;
   %end;
   ods listing; options notes;
%mend;

/*--------------------------------------------------------------------------
  Display Figure 9 and measure the Data2b data
  --------------------------------------------------------------------------*/
%measure(data=Data2b,n=10000)
%walk(n=2000)
%walkPlot

/*--------------------------------------------------------------------------
  Display Figure 10
  --------------------------------------------------------------------------*/
data tmp;
   x1=0; x2=0; output;
   x1=1; x2=0; output;
   run;
%walkDeadZone(scoredata=tmp)
proc print data=tmp; run;


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  Three Dimensions
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/


/*--------------------------------------------------------------------------
  The Data3 data set is sampled from a logistic model defined on a
  bivariate normal distribution, includes the interaction term, and is
  separated based on the probabilities.
  --------------------------------------------------------------------------*/
data Data3;
   pi=constant("pi");
   do i=1 to 100;
      retry:
      x1= rannor(&seed);
      x2= 0.75*rannor(&seed);
      x1x2=x1*x2;
      eta= 0.5 + 0.1*x1 + 0.2*x2 + 0.3*x1x2;
      if (eta < 1) then prb= exp(eta)/(1+exp(eta));
      else prb= 1/(1+exp(-eta));
      if (prb > 0.605) then y=1;
      else if (prb < .6) then y=0;
      else goto retry;
      output;
   end;
proc sort;
   by y;
   run;

/*--------------------------------------------------------------------------
  Identify the Dead Zone for the Data3 data set, then display Figure 11
  --------------------------------------------------------------------------*/
%usePred(data=Data3,model=x1|x2);
proc template;
   define statgraph myTpl;
   begingraph / drawspace=datavalue;
   layout overlayequated / &eqopts;
      contourplotparm x=s1 y=s2 z=sp / contourtype=gradient colormodel=TwoColorRamp;
      scatterplot x=x1 y=x2 / group=y includemissinggroup=false primary=true;
      drawtext textattrs=(color=GraphData1:contrastcolor) "Nonevents"
             / x=-.4 y=-2 anchor=left width=20;
      drawtext textattrs=(color=GraphData2:contrastcolor) "Events"
             / x=-3 y=-2 anchor=left width=20;
      drawtext textattrs=(color=GraphData1:contrastcolor) "Nonevents"
             / x=-3 y=0 anchor=left width=20;
   endlayout;
   endgraph;
   end;
proc sgrender data=out template=myTpl; run;

/*--------------------------------------------------------------------------
  The Data3b data set samples events and nonevents from non-intersecting
  ellipsoids in three-dimensional space with slightly different
  orientations.
  --------------------------------------------------------------------------*/
data Data3b;
   pi=constant("pi");
   theta=&theta;
   keep x1 x2 x3 y;
   do i=1 to 100;
      y=0;
      x1= rannor(&seed); x2= 0.5*rannor(&seed); x3= 0.5*rannor(&seed);
      output;
      y=1;
      z1= rannor(&seed); z2= 0.5*rannor(&seed); z3= 0.5*rannor(&seed)+2;
      y1= z1*cos(theta)+z3*sin(theta); y2= z2;  y3= -z1*sin(theta)+z2*cos(theta);
      x1= y1*cos(theta)-y2*sin(theta); x2= y1*sin(theta)+y2*cos(theta); x3= y3+1.7;
      output;
   end;
proc sort;
   by y;
   run;
data Data3b;
   set Data3b;
   pi=constant("pi");
   phi=33*pi/256;
   drop pi phi;
   r1= x1*cos(phi)-x3*sin(phi); r2= x2; r3= x1*sin(phi)+x3*cos(phi);
run;

%macro plot3b;
   /*--------------------------------------------------------------------------
     Displays the Data3b data set by projecting the data onto a
     surface so you can look along the edge of the Dead Zone.  The
     code is slightly more specialized due to the rotation and
     projection.
     --------------------------------------------------------------------------*/
   ods listing close; options nonotes;
   proc logistic data=Data3b;
      model y(event='1')=x:;
      output out=out p=p;
      store mymodel;
   run;
   proc sort data=out;
      by y;
      run;
   proc means data=out;
      var p;
      by y;
      output out=mout min=min max=max;
      run;
   data _null_;
      set mout;
      if y=0 then call symputx('maxp0',max);
      if y=1 then call symputx('minp1',min);
      run;
   proc means data=Data3b;
      var r1 r2 r3;
      output out=mout min=min1 min2 min3 max=max1 max2 max3;
      run;
   data _null_;
      set mout;
      %do j=1 %to 3;
         call symputx("xmin&j",min&j);
         call symputx("xmax&j",max&j);
      %end;
   run;
   data score;
      drop z1 z2 z3;
      pi=constant("pi");
      phi=-33*pi/256;
      do z1=0 to 200 by 1;
         do z2= 0 to 200 by 1;
            do z3= 0 to 200 by 1;
               %do j=1 %to 3; s&j= z&j/200*(&&xmax&j-&&xmin&j)+&&xmin&j; %end;
               x1= s1*cos(phi)-s3*sin(phi);
               x2= s2;
               x3= s1*sin(phi)+s3*cos(phi);
               output;
            end;
         end;
      end;
   run;
   proc plm restore=mymodel;
      score data=score out=out / ilink;
   run;
   data out;
      set out;
      drop x1 x2 x3;
      spx=(Predicted>&maxp0 & Predicted<&minp1);
   /*project onto s2-s3 axis before rendering*/
   proc sort data=out;
      by s2 s3;
      run;
   data out;
      set out;
      by s2 s3;
      retain sp 0;
      if first.s3 then sp=0;
      if spx=1 then sp=1;
      if last.s3 then output;
      run;
   data out;
      set Data3b out;
      run;
   proc template;
      define statgraph myTpl;
      begingraph / drawspace=datavalue;
      layout overlayequated / &eqopts yaxisopts=(label='x2')
         xaxisopts=(label='x1 cos(33(*ESC*){unicode pi}/256) - x3 sin(33(*ESC*){unicode pi}/256)');
         contourplotparm x=s3 y=s2 z=sp / contourtype=gradient colormodel=TwoColorRamp;
         scatterplot x=r3 y=r2 / group=y includemissinggroup=false primary=true;
         drawtext textattrs=(color=GraphData2:contrastcolor) "Events"
                / x=2.5 y=-1.3 anchor=left width=20;
         drawtext textattrs=(color=GraphData1:contrastcolor) "Nonevents"
                / x=2  y=-1.3 anchor=right width=25;
       endlayout;
      endgraph;
      end;
   ods graphics / maxobs=10000000;
   proc sgrender data=out template=myTpl;
   run;
%mend;

/*--------------------------------------------------------------------------
  Measure the Data3 and Data3b data sets
  --------------------------------------------------------------------------*/
%measure(data=Data3b,dim=3,n=10000)
%measure(data=Data3,dim=2,n=10000,model=x1 x2 x1*x2)

/*--------------------------------------------------------------------------
  Display Figure 12
  --------------------------------------------------------------------------*/
%plot3b


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  SEARCHING FOR THE CONVEX HULLS
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/


%macro cvexhull(data=Data2);
   /*--------------------------------------------------------------------------
     Draws a convex hull around the Data2 data by using the CVEXHULL
     statement in PROC IML.
     --------------------------------------------------------------------------*/
   ods listing close; options nonotes;
   proc iml;
      use &data;
      read all var{x1 x2} into x;
      read all var{y} into y;
      close &data;
      events=x[loc(y=1),];
      nonevents=x[loc(y=0),];
      idx= cvexhull(events);
      idx= idx[loc(idx>0)];
      hull=events[idx,];
      create ehull from hull;
      append from hull;
      close ehull;
      idx= cvexhull(nonevents);
      idx= idx[loc(idx>0)];
      hull=nonevents[idx,];
      create nhull from hull;
      append from hull;
      close nhull;
   quit;
   data _null_;
      set ehull;
      i=_n_;
      call symput("maxe",i);
      name=strip('eh1')||strip(i);
      call symput(name,col1);
      name=strip('eh2')||strip(i);
      call symput(name,col2);
   run;
   data _null_;
      set nhull;
      i=_n_;
      call symput("maxn",i);
      name=strip('nh1')||strip(i);
      call symput(name,col1);
      name=strip('nh2')||strip(i);
      call symput(name,col2);
   run;
   proc template;
      define statgraph myTpl;
      begingraph / drawspace=datavalue;
      layout overlayequated / &eqopts;
         %macro drawhull;
         beginpolygon x=&eh11 y=&eh21 / display=all
            outlineAttrs=GraphData2 transparency=0.5 fillattrs=(transparency=1);
            %do i=2 %to &maxe; draw x=&&eh1&i y=&&eh2&i; %end;
         endpolygon;
         beginpolygon x=&nh11 y=&nh21 / display=all
            outlineAttrs=GraphData1 transparency=0.5 fillattrs=(transparency=1);
            %do i=2 %to &maxn; draw x=&&nh1&i y=&&nh2&i; %end;
         endpolygon;
         %mend;
         %drawhull;
         lineparm x=&x1 y=&y1 slope=1 / lineattrs=(color=&linegray) clip=true;
         lineparm x=eval(-&x1) y=eval(-&y1) slope=1 / lineattrs=(color=&linegray) clip=true;
         scatterplot x=x1 y=x2 / group=y primary=true;
         drawtext textattrs=(color=GraphData2:contrastcolor) "Events"
                / x=-2.2 y=-1.8 anchor=right width=20;
         drawtext textattrs=(color=GraphData1:contrastcolor) "Nonevents"
                / x=-1.4 y=-1.8 anchor=left width=20;
      endlayout;
      endgraph;
      end;
   ods listing; options notes;
   proc sgrender data=&data template=myTpl;
   run;
%mend;

/*--------------------------------------------------------------------------
  Display Figure 13
  --------------------------------------------------------------------------*/
%cvexhull


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  The DISCRIM Procedure
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/


%macro discrim(method=,type=);
   /*--------------------------------------------------------------------------
     The DISCRIM macro runs PROC DISCRIM on the Data2 data set.  The
     CLASS statement tells PROC DISCRIM that we have two distinct data
     clouds represented by the Y variable.  The METHOD=NORMAL option
     makes normality assumptions about the data and uses the weighted
     distances to compute posterior probabilities and densities, and
     the POOL=NO option treats these two data clouds separately.  The
     TESTDATA data set tells PROC DISCRIM to score the data set
     generated by the makeScore macro.  The OUT and TESTOUT data sets
     contain posterior probabilities of having a specific Y value, and
     the OUTD and TESTOUTD data sets contain densities of the two data
     clouds.
   
     If you specify TYPE=DENSITY, then the remaining part of the
     program finds the minimum density estimates from the two
     estimated densities for inclusion in the event or nonevent
     distribution.  Compare these minumums to densities computed for
     the SCORE data set, and scores with predicted densities less than
     both minimums are either in the Dead Zone or lie far outside the
     hull of the data.  If you do not specify TYPE=DENSITY, the
     preceding is computed for the posteriors instead.
     Calls the makeScore and data2Plot macros.
   
     method= PROC DISCRIM method to pass
     type=   PROC DISCRIM type to pass
     --------------------------------------------------------------------------*/
   ods listing close; options nonotes;
   %makeScore(data=Data2,out=score)
   data tmp;
      set Data2;
      if y^=.;
      run;
   proc discrim data=tmp method=&method pool=no out=out outd=outdensity
      testdata=score testout=sout testoutd=soutdensity;
      class y;
      var x1 x2;
   run;
   proc sort data=out&type;
      by y;
      run;
   proc means data=out&type;
      var _0 _1;
      class y;
      output out=mout min=min0 min1;
   data _null_;
      set mout;
      if (y=0) then call symputx('min0',min0);
      if (y=1) then call symputx('min1',min1);
   run;
   data sout&type;
      set sout&type(rename=(_0=score0 _1=score1 x1=s1 x2=s2));
      if (score0 < &min0 & score1 < &min1) then sp=0;
      else if (score0 < &min0) then sp=1;
      else if (score1 < &min1) then sp=2;
      else sp=3;
   run;
   data out;
      set sout&type out&type;
      run;
   ods listing; options notes;
   %data2Plot(contour=true)
%mend;

/*--------------------------------------------------------------------------
  Displays Figures 14 and 15
  --------------------------------------------------------------------------*/
%discrim(method=normal)
%discrim(method=normal,type=density)

/*--------------------------------------------------------------------------
  Displays Figures 16 and 17
  --------------------------------------------------------------------------*/
%discrim(method=npar kernel=normal r=0.5);
%discrim(method=npar kernel=normal r=0.5,type=density);


/*--------------------------------------------------------------------------
  --------------------------------------------------------------------------
  SAMPLING FROM THE DEAD ZONE
  --------------------------------------------------------------------------
  --------------------------------------------------------------------------*/


%macro sample(n=10,data=Data2,model=x:,dim=2,seed=3939);
   /*--------------------------------------------------------------------------
     Generates a random sample of points from the Dead Zone for a given
     data set, and displays if there are 2 effects.
     Calls the makeMaxMin and makeScore macros.
   
     data=  names the input data set
     model= right-hand side of the MODEL statement
     dim=   number of continuous predictors
     n=     number of samples to draw
     seed=  initial seed
     --------------------------------------------------------------------------*/
   ods listing close; options nonotes;
   proc logistic data=&data outest=est;
      model y(event='1')=&model;
      output out=out p=p xbeta=xbeta;
      store mymodel;
   run;
   %makeMaxMin(data=out,est=est,dim=&dim)
   %makeScore(data=&data,dim=&dim)
   proc plm restore=mymodel;
      score data=score out=outs;
   run;
   /*ASSUMING that the last dimension is not degenerate, sample from a
     subsurface by dropping the last X and draw from the remaining
     dimensions. Then project upwards to the logistic regression
     surface, and reject if the last X is outside its data range*/
   data out;
      %do i=1 %to &n;
         mypi=ranuni(&seed)*(&minxb1-&maxxb0)+&maxxb0;
         attempts=0;
         do while (attempts < 10);
            %do j=1 %to %eval(&dim-1);
               t&j=ranuni(&seed)*(&&xmax&j-&&xmin&j)+&&xmin&j; %end;
            t&dim= ( mypi-&beta0 %do j=1 %to %eval(&dim-1); - t&j*&&beta&j %end; ) / &&beta&dim;
            if (t&dim < &&xmin&dim) then found=0;
               else if (t&dim > &&xmax&dim) then found=0;
               else found=1;
            attempts=attempts+1;
            if (found=1) then do;
               attempts=10;
               output;
            end;
         end;
      %end;
   run;
   data out;
      set &data out;
      run;
   ods listing; options notes;
   %if %eval(&dim=2) %then %do;
      proc template;
         define statgraph myTpl;
         begingraph / drawspace=datavalue;
         layout overlayequated / &eqopts;
            scatterplot x=x1 y=x2 / group=y includemissinggroup=false primary=true;
            scatterplot x=t1 y=t2 / markerattrs=(size=3 symbol=circlefilled color=&linegray);
         endlayout;
         endgraph;
      end;
      proc sgrender data=out template=myTpl;
      run;
   %end;
%mend;

/*--------------------------------------------------------------------------
  Display Figure 18
  --------------------------------------------------------------------------*/
%sample(n=1000)

