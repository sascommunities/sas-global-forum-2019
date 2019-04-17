%macro rskmimpl_base_env(work_group=);

    %if %sysfunc(libref(mimp_sas)) ne 0 %then %do;
        %put ERROR:(rskmimpl_base_env) Library MIMP_SAS is not defined. Cannot create work group risk enviroment.;
        %abort cancel;
    %end;

    %if %sysfunc(libref(mimp_env)) ne 0  %then %do;
        %if %sysevalf(%superq(work_group)=,boolean) %then %do;
            %put ERROR:(rskmimpl_base_env) The argument "work_group" cannot be empty when the library MIMP_ENV is not defined. No work group risk enviroment is created.;
            %abort cancel;
        %end;
        
        %local mimp_sas_path end_char root_dir path_sep risk_group_root_dir;

        %let mimp_sas_path=%sysfunc(pathname(mimp_sas));
        %let end_char=%substr(&mimp_sas_path, %length(&mimp_sas_path));

        %if "&end_char" eq "/" or "&end_char" eq "\" %then %do;
            %let root_dir=%substr(&mimp_sas_path, 1, %eval(%length(&mimp_sas_path)-57));
        %end;
        %else %do;
            %let root_dir=%substr(&mimp_sas_path, 1, %eval(%length(&mimp_sas_path)-56));
        %end;

        %let path_sep=%substr(&root_dir, %length(&root_dir));
        %let risk_group_root_dir = &root_dir.SASRiskWorkGroup&path_sep.groups;

        libname mimp_env "&risk_group_root_dir.&path_sep.&work_group.&path_sep.SASModelImplementationPlatform&path_sep.input&path_sep.mimp_env";
    %end;

    proc risk;
       env new=mimp_env.base_risk_env inherit=(mimp_sas.sas_risk_env) 
       label="Customer site specific base environment";

       /*- create default project -*/
       project mipProject   projectmethods = base_project;

       env save;
    run;

    proc compile env=mimp_env.base_risk_env
                 outlib=mimp_env.base_risk_env
                 package = funcs;

      method base_project kind=project;
         beginblock thread_init;
           call streaminit("PCG");
         endblock;
      endmethod;
    run;
    quit;
    
%mend rskmimpl_base_env;
%rskmimpl_base_env(work_group=&sysparm);
