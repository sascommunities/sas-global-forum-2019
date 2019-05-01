data nodes;
  infile datalines dsd;
  length node $2. label $2.;
  input node $ label $;
  datalines;
n0, 22
n1, 19
n2, 8
n3, 1
n4, 20
n5, 15
n6, 28
n7, 9
n8, 11
n9, 23
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
