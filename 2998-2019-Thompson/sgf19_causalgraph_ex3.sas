

proc causalgraph common(only);
   model "Original Model"
      PKD ==> DialysisType Mortality PeritonealDialysis,
      Age ==> PKD ComorbidityIndex AssistanceType Mortality,
      ComorbidityIndex ==> PKD PeritonealDialysis Mortality AssistanceType,
      Gender ==> ComorbidityIndex AssistanceType,
      AssistanceType ==> DialysisType Mortality,
      PeritonealDialysis ==> DialysisType;
   model "Reduced Model"
      PKD ==> DialysisType Mortality PeritonealDialysis,
      Age ==> PKD ComorbidityIndex AssistanceType Mortality,
      ComorbidityIndex ==> PKD PeritonealDialysis Mortality AssistanceType,
      Gender ==> ComorbidityIndex AssistanceType,
      AssistanceType ==> DialysisType,
      PeritonealDialysis ==> DialysisType;
   identify PKD ==> Mortality | PeritonealDialysis;
   unmeasured AssistanceType;
run;