data nodes;
  infile datalines dsd;
  length node $2. label $3.;
  input node $ label $;
  datalines;
n0, 173
n1, 155
n2, 180
n3, 117
n4, 140
;

data links;
  infile datalines dsd;
  length from $2. to $2.;
  input from $ to $;
  datalines;
n0, n1
n0, n2
n0, n3
n0, n4
n1, n2
n1, n4
n2, n4
;
