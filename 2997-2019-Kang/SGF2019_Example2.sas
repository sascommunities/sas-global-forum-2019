/****************************************************************/
/*           S A S   G L O B A L   F O R U M   2 0 1 9          */
/*                                                              */
/*   TITLE: Estimating Source Signals with Dimension Reduction  */
/* PRODUCT: SAS Viya, Visual Statistics                         */
/*                                                              */
/****************************************************************/

data mycas.Signals2;
   keep t x:;
   array S[200,3];     /* S: source signals */
   array A[3,3];       /* A: mixing matrix */
   array x[4] x1-x4;   /* X: observed signals */

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
      x[4] = 0.1*uniform(67890);
      output;
   end;
run;

/* Extract independent components with dimension reduction */

proc ica data=mycas.Signals2 eigthresh=0.004 noscale seed=345;
   var x1-x4;
   output out=mycas.Scores2 component=c copyvar=t;
run;

proc template;
   define statgraph Panel4;
      beginGraph;
         layout lattice / rows=3
                          columns=1
                          rowgutter=10
                          columndatarange=unionall
                          order=packed;

         columnaxes;
            columnaxis / label="t";
         endcolumnaxes;

         layout overlay / yaxisopts=
            (linearopts=(viewmin=-3 viewmax=3 tickvaluelist=(-3 0 3)));
            seriesplot x=t y=c1;
         endlayout;

         layout overlay / yaxisopts=
            (linearopts=(viewmin=-2 viewmax=2 tickvaluelist=(-2 0 2)));
            seriesplot x=t y=c2;
         endlayout;

         layout overlay / yaxisopts=
            (linearopts=(viewmin=-2 viewmax=2 tickvaluelist=(-2 0 2)));
            seriesplot x=t y=c3;
         endlayout;

         endlayout;
      endGraph;
   end;
run;

proc sgrender data=mycas.Scores2 template=Panel4;
run;

/* Extract independent components with full dimensions */

proc ica data=mycas.Signals2 noscale seed=345;
   var x1-x4;
   output out=mycas.Scores2a component=c copyvar=t;
run;

proc template;
   define statgraph Panel5;
      beginGraph;
         layout lattice / rows=4
                          columns=1
                          rowgutter=10
                          columndatarange=unionall
                          order=packed;

         columnaxes;
            columnaxis / label="t";
         endcolumnaxes;

         layout overlay / yaxisopts=(linearopts=(viewmin=-4 viewmax=0 tickvaluelist=(-4 -2 0)));
            seriesplot x=t y=c1;
         endlayout;

         layout overlay / yaxisopts=(linearopts=(viewmin=-2 viewmax=2 tickvaluelist=(-2 0 2)));
            seriesplot x=t y=c2;
         endlayout;

         layout overlay / yaxisopts=(linearopts=(viewmin=-2 viewmax=2 tickvaluelist=(-2 0 2)));
            seriesplot x=t y=c3;
         endlayout;

         layout overlay / yaxisopts=(linearopts=(viewmin=-3 viewmax=3 tickvaluelist=(-3 0 3)));
            seriesplot x=t y=c4;
         endlayout;

         endlayout;
      endGraph;
   end;
run;

proc sgrender data=mycas.Scores2a template=Panel5;
run;

