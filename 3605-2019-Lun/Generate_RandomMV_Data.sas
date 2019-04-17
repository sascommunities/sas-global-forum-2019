***********************************************************************;
*** This SAS macro uses Iman-Conover method to generate multivariate data 
*** with known marginals and known rank correlation.  ***
** (Macro adapted from Wicklin, R. 2013. Simulating Data with SAS. Cary, NC: SAS Institute Inc.)
***********************************************************************;
*** --- Macro: genMVdata(seed=, nSize=, nvar=, distList=, corrMat=, logNormSigma=, Pareto_a=, out=) ---;
*** --- Input: seed, nSize, nvar, distList, corrMat, logNormSigm, Pareto_a, out ---;
*** seed: seed for random generation;
*** nSize: the size of sample;
*** nvar: the number of variables;
*** distList:  a list of marginal distributions for multivariate data;
*** corrMat: the structure of correlation Matrix;
*** logNormSigm: the sigma (standard deviation) of log-normal distribution;
*** Pareto_a: the "a" parameter of Pareto distribution;
*** out: the name of output dataset;
*** --- Output: out ---;	 

%macro genMVdata(seed=, nSize=, nvar=, distList=, corrMat=, logNormSigma=, Pareto_a=, out=);
proc iml;
start ImanConoverTransform(Y, C);
	X = Y;
	N = nrow(X);
	R = j(N, ncol(X));
	
	/* compute scores of each column */
	do i = 1 to ncol(X);
	   h = quantile("Normal", rank(X[,i])/(N+1));
	   R[,i] = h;
	end;
	
	/* these matrices are transposes of those in Iman & Conover */
	Q = root(corr(R));
	P = root(C);
	S = solve(Q, P);
	M = R*S;
	
	/* reorder columns of X to have same ranks as M. In Iman-Conover (1982), 
	the matrix is called R_B.*/
	do i = 1 to ncol(M);
	   rank = rank(M[,i]);
	   y = X[,i];
	   call sort(y);
	   X[,i] = y[rank];
	end;
	return(X);
finish;

/* Step 1: Specify marginal distribution */
call randseed(&seed);
N = &nSize;
A = j(N, &nvar);
y = j(N, 1);
distrib = &distList;
do i = 1 to ncol(distrib);
	
	if distrib[i]='LOGNORMAL' then do;
		mu = 0;
		sigma = &logNormSigma;
    	call randgen(y, 'LOGNORMAL', mu, sigma);
	end;

	if distrib[i]='NORMAL' then do;
		mu = 0;
		sigma = 1.0;
		call randgen(y, 'NORMAL', mu, sigma);
	end;

	if distrib[i]='EXPONENTIAL' then do;
		lambda = 1.0;
    	call randgen(y, 'EXPONENTIAL', lambda);
	end;

	if distrib[i]='UNIFORM' then do;
		aa = 0;
		bb = 1.0;
    	call randgen(y, 'UNIFORM', aa, bb);
	end;
	
	if distrib[i]='PARETO' then do;
		aa = &Pareto_a;
		kk = 1.0;
    	call randgen(y, 'PARETO', aa, kk);
	end;
	
	if distrib[i]='GAMMA' then do;
		aa = 1.0;
		kk = 1.0;
    	call randgen(y, 'GAMMA', aa, kk);
	end;

	A[,i] = y;
end;

/* Step 2: specify target rank correlation */
C = &corrMat;
X = ImanConoverTransform(A, C);

/* write to SAS data set */
create &out from X[c=("x1":"x&nvar")];
append from X;
close &out;
quit;
%mend genMVdata;


