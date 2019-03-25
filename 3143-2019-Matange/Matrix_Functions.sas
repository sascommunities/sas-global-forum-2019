options cmplib=sasuser.funcs;


proc fcmp outlib=sasuser.funcs.mat;
  subroutine MatInv(Mat[*,*], InvMat[*,*]);
  outargs InvMat;
  call inv(Mat, InvMat);
  endsub;

  subroutine MatMult(A[*,*], B[*,*], C[*,*]);
  outargs C;
  call mult(A, B, C);
  endsub;

  subroutine MatIdent(A[*,*]);
  outargs A;
  call identity(A);
  endsub;
run;
quit;

