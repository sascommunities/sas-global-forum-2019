data nodes;
  infile datalines dsd;
  length node $2. label $2.;
  input node $ label $;
  datalines;
n0, 15
n1, 13
n2, 5
n3, 1
n4, 13
n5, 10
n6, 19
n7, 6
n8, 7
n9, 15
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
