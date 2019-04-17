proc risk;
  env new=mipenv.risk_env inherit=(mimp_env.base_risk_env);
  setoptions NOBACKSAVE;
  env save;
run;

proc compile env=mipenv.risk_env
             outlib=mipenv.risk_env
             package = funcs;

  method base_project kind=project;
     beginblock thread_init;
       call streaminit("TF2");
     endblock;
  endmethod;
run;
quit;
