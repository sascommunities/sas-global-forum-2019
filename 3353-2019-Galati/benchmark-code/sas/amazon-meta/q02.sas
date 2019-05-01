data nodes;
  infile datalines dsd;
  length node $2. label $20.;
  input node $ label $;
  datalines;
n0, Video: Kids & Family
n1, DVD: Kids & Family
n2, DVD: Comedy
n3, Video: Kids & Family
n4, DVD: Kids & Family
n5, Video: Kids & Family
n6, Video: Kids & Family
n7, DVD: Kids & Family
n8, Video: Kids & Family
n9, DVD: Comedy
;

data links;
  infile datalines dsd;
  length from $2. to $2.;
  input from $ to $;
  datalines;
n0, n2
n2, n4
n4, n5
n1, n6
n2, n6
n0, n7
n2, n7
n3, n7
n4, n7
n2, n8
n7, n8
n0, n9
n2, n9
n3, n9
n4, n9
n5, n9
n6, n9
;
