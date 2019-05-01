data nodes;
  infile datalines dsd;
  length node $3. label $2.;
  input node $ label $;
  datalines;
n0, 8
n1, 22
n2, 12
n3, 6
n4, 12
n5, 16
n6, 29
n7, 21
n8, 12
n9, 22
n10, 4
n11, 30
n12, 15
n13, 29
n14, 21
n15, 30
n16, 18
n17, 17
n18, 17
n19, 18
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
