data nodes;
  infile datalines dsd;
  length node $2. label $2.;
  input node $ label $;
  datalines;
n0, 22
n1, 19
n2, 15
n3, 28
n4, 9
;

data links;
  infile datalines dsd;
  length from $2. to $2.;
  input from $ to $;
  datalines;
n0, n2
n1, n2
n1, n3
n2, n4
;
