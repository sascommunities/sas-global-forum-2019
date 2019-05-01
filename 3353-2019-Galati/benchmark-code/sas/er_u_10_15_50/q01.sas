data nodes;
  infile datalines dsd;
  length node $2. label $2.;
  input node $ label $;
  datalines;
n0, 36
n1, 32
n2, 24
n3, 47
n4, 15
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
