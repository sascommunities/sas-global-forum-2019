data nodes;
  infile datalines dsd;
  length node $3. label $2.;
  input node $ label $;
  datalines;
n0, 14
n1, 36
n2, 19
n3, 10
n4, 19
n5, 26
n6, 48
n7, 34
n8, 20
n9, 36
n10, 6
n11, 50
n12, 25
n13, 48
n14, 35
n15, 50
n16, 29
n17, 27
n18, 27
n19, 29
;

data links;
  infile datalines dsd;
  length from $3. to $3.;
  input from $ to $;
  datalines;
n2, n3
n0, n4
n2, n6
n0, n7
n5, n7
n9, n10
n8, n11
n3, n12
n5, n13
n6, n13
n11, n14
n1, n15
n10, n16
n12, n16
n1, n17
n9, n17
n3, n18
n8, n18
n3, n19
;
