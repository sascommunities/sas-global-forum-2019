/****************************************************************/
/*           S A S   G L O B A L   F O R U M   2 0 1 9          */
/*                                                              */
/*   TITLE: Estimating Source Signals Using PROC ICA            */
/* PRODUCT: SAS Viya, Visual Statistics                         */
/*                                                              */
/****************************************************************/

%let sysparm=nworkers:2;  /* this sets the number of nodes to 2 */
%cassetup;
libname mycas cas sessref=sascas1 datalimit=all;

data mycas.Signals1;
   keep t x:;
   array S[200,3];     /* S: source signals */
   array A[3,3];       /* A: mixing matrix */
   array x[3] x1-x3;   /* X: mixed signals */

   N = 200;

   do i = 1 to 3;
      do j = 1 to 3;
         A[i,j] = 0.7*uniform(12345);
      end;
   end;

   do i = 1 to N;
      S[i,1] = cos(i/3);
      S[i,2] = 0.4*((mod(i,23)-11)/7)**5;
      S[i,3] = ((mod(i,29)-7)/11)-0.7;
   end;

   do i = 1 to N;
      t = i;
      do j = 1 to 3;
         x[j] = 0;
         do k = 1 to 3;
            x[j] = x[j] + S[i,k]*A[k,j];
         end;
      end;
      output;
   end;
run;

proc iml;
   n = 200;
   t = 1:n;

   s = j(3,n,0);
   s[1,] = cos(t/3);
   s[2,] = 0.4*((mod(t,23)-11)/7)##5;
   s[3,] = (mod(t,29)-7)/11-0.7;
   s = s`;

   varNames = "s1":"s3";
   create sourceSignals from s [colname=varNames];
   append from s;
   close sourceSignals;
quit;

data sourceSignals; set sourceSignals; t=_N_;
run;

proc template;
   define statgraph Panel1;
      beginGraph;
         layout lattice / rows=3
                          columns=1
                          rowgutter=10
                          columndatarange=unionall
                          order=packed;

         columnaxes;
            columnaxis / label="t";
         endcolumnaxes;

         layout overlay / yaxisopts=(linearopts=(viewmin=-2 viewmax=2 tickvaluelist=(-2 0 2)));
            seriesplot x=t y=s1;
         endlayout;

         layout overlay / yaxisopts=(linearopts=(viewmin=-4 viewmax=4 tickvaluelist=(-4 0 4)));
            seriesplot x=t y=s2;
         endlayout;

         layout overlay / yaxisopts=(linearopts=(viewmin=-2 viewmax=2 tickvaluelist=(-2 0 2)));
            seriesplot x=t y=s3;
         endlayout;

         endlayout;
      endGraph;
   end;
run;

proc sgrender data=sourceSignals template=Panel1;
run;

proc template;
   define statgraph Panel2;
      beginGraph;
         layout lattice / rows=3
                          columns=1
                          rowgutter=10
                          columndatarange=unionall
                          order=packed;

         columnaxes;
            columnaxis / label="t";
         endcolumnaxes;

         layout overlay / yaxisopts=(linearopts=(viewmin=-2 viewmax=2 tickvaluelist=(-2 0 2)));
            seriesplot x=t y=x1;
         endlayout;

         layout overlay / yaxisopts=(linearopts=(viewmin=-2 viewmax=2 tickvaluelist=(-2 0 2)));
            seriesplot x=t y=x2;
         endlayout;

         layout overlay / yaxisopts=(linearopts=(viewmin=-3 viewmax=3 tickvaluelist=(-3 0 3)));
            seriesplot x=t y=x3;
         endlayout;

         endlayout;
      endGraph;
   end;
run;

proc sgrender data=mycas.Signals1 template=Panel2;
run;

proc ica data=mycas.Signals1 seed=345;
   var x1-x3;
   output out=mycas.Scores1 component=c copyvar=t;
run;

proc template;
   define statgraph Panel3;
      beginGraph;
         layout lattice / rows=3
                          columns=1
                          rowgutter=10
                          columndatarange=unionall
                          order=packed;

         columnaxes;
            columnaxis / label="t";
         endcolumnaxes;

         layout overlay / yaxisopts=(linearopts=(viewmin=-2 viewmax=2 tickvaluelist=(-2 0 2)));
            seriesplot x=t y=c1;
         endlayout;

         layout overlay / yaxisopts=(linearopts=(viewmin=-3 viewmax=3 tickvaluelist=(-3 0 3)));
            seriesplot x=t y=c2;
         endlayout;

         layout overlay / yaxisopts=(linearopts=(viewmin=-2 viewmax=2 tickvaluelist=(-2 0 2)));
            seriesplot x=t y=c3;
         endlayout;

         endlayout;
      endGraph;
   end;
run;

proc sgrender data=mycas.Scores1 template=Panel3;
run;

