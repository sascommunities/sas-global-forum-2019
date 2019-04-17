


proc causalgraph maxsize=min common imap;
   model "Base Model"
      Age ==> HistoryFracture BMD ChronicDisease GaitSpeed,
      BMI <==> ChronicDisease ==> PsychotropicUse GlucocorticoidUse,
      BMI ==> VitaminD BMD,
      PsychotropicUse ==> FiveTSTS GaitSpeed,
      GlucocorticoidUse ==> GaitSpeed FiveTSTS,
      BMD ==> HistoryFracture VitaminD Fracture,
      HistoryFracture ==> VitaminD,
      GaitSpeed ==> Fracture HistoryFalls;
   model "Modified Model"
      Age ==> HistoryFracture BMD ChronicDisease GaitSpeed,
      BMI <==> ChronicDisease ==> PsychotropicUse GlucocorticoidUse GaitSpeed,
      BMI ==> VitaminD BMD,
      PsychotropicUse ==> FiveTSTS GaitSpeed,
      GlucocorticoidUse ==> GaitSpeed FiveTSTS,
      BMD ==> HistoryFracture VitaminD Fracture,
      HistoryFracture ==> VitaminD,
      GaitSpeed ==> Fracture HistoryFalls;
   identify PsychotropicUse ==> Fracture;
   unmeasured ChronicDisease BMD HistoryFalls HistoryFracture;
run;


proc causalgraph nolist imap=global;
   model "Base Model"
      Age ==> HistoryFracture BMD ChronicDisease GaitSpeed,
      BMI <==> ChronicDisease ==> PsychotropicUse GlucocorticoidUse,
      BMI ==> VitaminD BMD,
      PsychotropicUse ==> FiveTSTS GaitSpeed,
      GlucocorticoidUse ==> GaitSpeed FiveTSTS,
      BMD ==> HistoryFracture VitaminD Fracture,
      HistoryFracture ==> VitaminD,
      GaitSpeed ==> Fracture HistoryFalls;
   model "Modified Model"
      Age ==> HistoryFracture BMD ChronicDisease GaitSpeed,
      BMI <==> ChronicDisease ==> PsychotropicUse GlucocorticoidUse GaitSpeed,
      BMI ==> VitaminD BMD,
      PsychotropicUse ==> FiveTSTS GaitSpeed,
      GlucocorticoidUse ==> GaitSpeed FiveTSTS,
      BMD ==> HistoryFracture VitaminD Fracture,
      HistoryFracture ==> VitaminD,
      GaitSpeed ==> Fracture HistoryFalls;
   identify PsychotropicUse ==> Fracture;
   unmeasured ChronicDisease BMD HistoryFalls HistoryFracture;
   ods output Imap=IndepData;
run;

data IndepDataObs;
   set IndepData;
   if Observable = 0 then delete;
run;

proc sort data=IndepDataObs;
   by Set1 Set2 CondSet;
run;

data UniqueIndep CommonIndep;
   set IndepDataObs;
   by Set1 Set2 CondSet;
   if (First.Set1 and Last.Set1) or (First.Set2 and Last.Set2) or (First.CondSet and Last.CondSet) then output UniqueIndep;
   else output CommonIndep;
run;

proc print data=UniqueIndep;
   var Model Set1 Set2 CondSet;
run;