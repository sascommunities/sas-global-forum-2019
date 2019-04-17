/* Macro function for conducting logrank test for left truncated data
/* Maintainer: Zhen-Huan Hu <zhu@mcw.edu>
/* Last change: 2018-03-19
/*
/* -------------------------------------------- */
/* Functions and their basic uses:
/*
/* %lt_logranktest(indata =, outtest = _outtest_, strata = , event =, intv =, ltime =, flemingp = 0, flemingq = 0, noprint = 0);
/*
/* INDATA:	  Name of the input data set
/* OUTDATA:       Name of the output data set (optional)
/* STRATA:	  Main group
/* EVENT:	  Event of interest (default: dead)
/* INTV:	  Time to the event / right censoring
/* LTIME:         Left truncation time
/* FLEMINGP       Fleming’s weight p (optional, default: 0)
/* FLEMINGQ       Fleming’s weight q (optional, default: 0)
/* NOPRINT:       Toggle whether print the results (default: 0)
/* -------------------------------------------- */

%macro lt_logranktest(indata =, outtest = _outtest_, strata = , event =, intv =, ltime =, flemingp = 0, flemingq = 0, noprint = 0);
  proc iml;
    use &indata;
    read all var {&strata &event &intv &ltime};
    close &indata;

    * Check DF;
    bystrata = unique(&strata);
    ns = ncol(bystrata);
    df = ns - 1;
    if df = 0 then do;
      chisq = .; probchisq = .;
    end;
    else do;
      * Calculate d, Y for the pooled sample;
      time_pooled = t(unique(&intv));
      call sort(time_pooled);
      nt_pooled = nrow(time_pooled);
      natrisk_pooled = j(nt_pooled, 1, .);
      nevents_pooled = j(nt_pooled, 1, .);
      do t = 1 to nt_pooled;
        natrisk_pooled[t] = ncol(loc(&ltime < time_pooled[t] & time_pooled[t] <= &intv));
        nevents_pooled[t] = ncol(loc(&event = 1 & &intv = time_pooled[t]));
      end;

      * Calculate d and Y for each group;
      natrisk = j(nt_pooled, ns, .);
      nevents = j(nt_pooled, ns, .);
      surv = j(nt_pooled, ns, .);    
      do s = 1 to ns;
        loc_s = loc(&strata = bystrata[s]);
        do t = 1 to nt_pooled;
          natrisk[t, s] = ncol(loc(&ltime[loc_s] < time_pooled[t] & time_pooled[t] <= &intv[loc_s]));
          nevents[t, s] = ncol(loc(&event[loc_s] = 1 & &intv[loc_s] = time_pooled[t]));
        end;
      end;

      * Calculate KM est for the pooled sample and weight;
      loc_pooled = loc(natrisk_pooled > 0);
      surv_pooled = j(nt_pooled, 1, .);
      surv_pooled[loc_pooled] = cuprod(1 - nevents_pooled[loc_pooled] / natrisk_pooled[loc_pooled]);
      weight = j(nt_pooled, 1, .);
      weight[1] = %if &flemingq = 0 %then 1; %else 0;;
      weight[2: nt_pooled] = (surv_pooled[1: (nt_pooled - 1)] ## &flemingp) # ((1 - surv_pooled[1: (nt_pooled - 1)]) ## &flemingq);

      * Calculate logrank p;
      z = j(df, 1, 0);
      sigma = j(df, df, 0);
      do j = 1 to df;
        loc_pooled = loc(natrisk_pooled > 1);
        z[j] = sum(weight[loc_pooled] #
        (nevents[loc_pooled, j] - natrisk[loc_pooled, j] # nevents_pooled[loc_pooled] / natrisk_pooled[loc_pooled]));
        do g = 1 to j;
          if g = j then do;
            sigma[j, j] = sum((weight[loc_pooled] ## 2) #
            (natrisk[loc_pooled, j] / natrisk_pooled[loc_pooled]) # (1 - natrisk[loc_pooled, j] / natrisk_pooled[loc_pooled]) #
            ((natrisk_pooled[loc_pooled] - nevents_pooled[loc_pooled]) / (natrisk_pooled[loc_pooled] - 1)) # nevents_pooled[loc_pooled]);
          end;
          else do;
            sigma[j, g] = -sum((weight[loc_pooled] ## 2) #
            (natrisk[loc_pooled, j] / natrisk_pooled[loc_pooled]) # (natrisk[loc_pooled, g] / natrisk_pooled[loc_pooled]) #
            ((natrisk_pooled[loc_pooled] - nevents_pooled[loc_pooled]) / (natrisk_pooled[loc_pooled] - 1)) # nevents_pooled[loc_pooled]);
            sigma[g, j] = sigma[j, g];
          end;
        end;
      end;
      chisq = t(z) * inv(sigma) * z;
      probchisq = 1 - probchi(chisq, df);
    end;

    test = 'Log-Rank';
    flemingpq = "Fleming(&flemingp,&flemingq)";
    create &outtest var {test flemingpq chisq df probchisq};
    append;
    close &outtest;
  quit;

  %if &noprint = 0 %then %do;
    title "Log-Rank Test for Survival Probabilities";
    proc report data = &outtest nowd;
    run;
    title;
  %end;
%mend;
