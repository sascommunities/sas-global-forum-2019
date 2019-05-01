data nodes;
  infile datalines dsd;
  length node $2. label $3.;
  input node $ label $;
  datalines;
n0, 282
n1, 331
n2, 272
n3, 184
n4, 33
n5, 196
n6, 274
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
n0, n6
n1, n3
n1, n4
n1, n5
n2, n4
n2, n6
n3, n4
;
