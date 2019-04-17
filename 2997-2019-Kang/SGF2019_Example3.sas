/****************************************************************/
/*           S A S   G L O B A L   F O R U M   2 0 1 9          */
/*                                                              */
/*   TITLE: Finding Underlying Factors in Macroeconomic Data    */
/* PRODUCT: SAS Viya, Visual Statistics                         */
/*                                                              */
/****************************************************************/

proc contents data=sashelp.citimon varnum;
   ods select position;
run;

proc template;
   define statgraph panel6;
      beginGraph / designwidth=640px designheight=1200px;
         layout lattice / rows=9
                          columns=2
                          rowgutter=5
                          columngutter=10
                          order=columnmajor
                          shrinkfonts=true
                          columndatarange=unionall;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='CCIUAC');
            seriesplot x=DATE y=CCIUAC;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='CCIUTC');
            seriesplot x=DATE y=CCIUTC;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='CONB');
            seriesplot x=DATE y=CONB;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='CONQ');
            seriesplot x=DATE y=CONQ;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='EEC');
            seriesplot x=DATE y=EEC;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='EEGP');
            seriesplot x=DATE y=EEGP;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='EXVUS');
            seriesplot x=DATE y=EXVUS;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='FM1');
            seriesplot x=DATE y=FM1;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='FM1D82');
            seriesplot x=DATE y=FM1D82;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='FSPCAP');
            seriesplot x=DATE y=FSPCAP;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='FSPCOM');
            seriesplot x=DATE y=FSPCOM;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='FSPCON');
            seriesplot x=DATE y=FSPCON;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='IP');
            seriesplot x=DATE y=IP;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='LHUR');
            seriesplot x=DATE y=LHUR;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='LUINC');
            seriesplot x=DATE y=LUINC;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='PW');
            seriesplot x=DATE y=PW;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='RCARD');
            seriesplot x=DATE y=RCARD;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on label='RTRR');
            seriesplot x=DATE y=RTRR;
         endlayout;

         endlayout;
      endGraph;
   end;
run;

proc sgrender data=sashelp.citimon template=Panel6;
run;

data mycas.citimon;
   set sashelp.citimon;
run;

proc ica data=mycas.citimon n=7 seed=345;
   var CCIUAC CCIUTC CONB CONQ
       EEC EEGP EXVUS
       FM1 FM1D82 FSPCAP FSPCOM FSPCON
       IP LHUR LUINC PW RCARD RTRR;
   output out=mycas.Scores3 component=c copyvar=DATE;
run;

proc template;
   define statgraph panel7;
      beginGraph / designwidth=640px designheight=1200px;
         layout lattice / rows=7
                          columns=1
                          rowgutter=10
                          columndatarange=unionall;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on);
            seriesplot x=DATE y=c1;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on);
            seriesplot x=DATE y=c2;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on);
            seriesplot x=DATE y=c3;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on);
            seriesplot x=DATE y=c4;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on);
            seriesplot x=DATE y=c5;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on);
            seriesplot x=DATE y=c6;
         endlayout;

         layout overlay / xaxisopts=(griddisplay=on) yaxisopts=(griddisplay=on);
            seriesplot x=DATE y=c7;
         endlayout;

         endlayout;
      endGraph;
   end;
run;

proc sgrender data=mycas.Scores3 template=Panel7;
run;

