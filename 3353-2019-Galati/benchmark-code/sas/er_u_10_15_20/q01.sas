data nodes;
  infile datalines dsd;
  length node $2. label $2.;
  input node $ label $;
  datalines;
n0, 15
n1, 13
n2, 10
n3, 19
n4, 6
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
