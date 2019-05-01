data nodes;
  infile datalines dsd;
  length node $2. label $2.;
  input node $ label $;
  datalines;
n0, 36
n1, 32
n2, 13
n3, 1
n4, 32
n5, 24
n6, 47
n7, 15
n8, 18
n9, 38
;

data links;
  infile datalines dsd;
  length from $2. to $2.;
  input from $ to $;
  datalines;
n2, n3
n2, n4
n0, n5
n1, n5
n1, n6
n2, n6
n5, n7
n4, n8
n8, n9
;
