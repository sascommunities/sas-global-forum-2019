
/* SIMULATION AND ANALYSIS OF SAMPLE DATA */

data StatinPSA;
   drop ii;
   call streaminit(1000);
   do ii = 1 to 5000;
      Age = rand("Uniform", 55, 75);
      BMI = rand("Normal", 27.0 - 0.01*Age, 0.7);
      Aspirin = rand("Bernoulli", logistic(-8.0 + 0.10*Age + 0.03*BMI));
      StatinUse = rand("Bernoulli", logistic(-13.0 + 0.10*Age + 0.20*BMI));
      Cancer = rand("Bernoulli", logistic(2.2 - 0.05*Age + 0.01*BMI
                                          - 0.04*StatinUse + 0.02*Aspirin));
      PSA = rand("Normal", 6.8 + 0.04*Age - 0.15*BMI - 0.60*StatinUse
                                          + 0.55*Aspirin + 1.00*Cancer,0.7);
      output;
   end;
run;

proc print data=StatinPSA(obs=10);
run;

proc causalgraph;
   model "StatinUse Effect on PSA"
      BMI ==> Cancer StatinUse PSA Aspirin,
      StatinUse ==> Cancer PSA,
      Cancer ==> PSA,
      Age ==> BMI StatinUse Aspirin PSA Cancer,
      Aspirin ==> PSA Cancer;
   identify StatinUse ==> PSA;
run;

proc causaltrt data=StatinPSA;
   class StatinUse Cancer Aspirin;
   psmodel StatinUse(event='1') = Age BMI;
   model PSA;
run;

proc causaltrt data=StatinPSA;
   class StatinUse Cancer Aspirin;
   psmodel StatinUse(event='1') = Age Aspirin BMI;
   model PSA;
run;

proc ttest data=StatinPSA;
   class StatinUse;
   var PSA;
run;



/* SIMULATION OF POPULATION ATE */

data RCTStatinPSA;
   drop ii;
   call streaminit(1000);
   do ii = 1 to 1000000;
      Age = rand("Uniform", 55, 75);
      BMI = rand("Normal", 27.0 - 0.01*Age, 0.7);
      Aspirin = rand("Bernoulli", logistic(-8.0 + 0.10*Age + 0.03*BMI));
      StatinUse = rand("Bernoulli", 0.5);
      Cancer = rand("Bernoulli", logistic(2.2 - 0.05*Age + 0.01*BMI - 0.04*StatinUse + 0.02*Aspirin));
      PSA = rand("Normal", 6.8 + 0.04*Age - 0.15*BMI - 0.60*StatinUse + 0.55*Aspirin + 1.00*Cancer,0.7);
      output;
   end;
run;

proc sort data=RCTStatinPSA;
   by StatinUse;
run;

proc means data=RCTStatinPSA;
   by StatinUse;
run;
/* The true value of the ATE is 5.345 - 5.953 = -0.608 */

