data nodes;
  infile datalines dsd;
  length node $2. label $25.;
  input node $ label $;
  datalines;
n0, Music: Miscellaneous
n1, DVD: Drama
n2, Video: Horror
n3, DVD: Horror
n4, Music: Miscellaneous
n5, DVD: Mystery & Suspense
n6, Book: Mystery & Thrillers
n7, Video: Comedy
n8, DVD: Action & Adventure
n9, DVD: Horror
;

data links;
  infile datalines dsd;
  length from $2. to $2.;
  input from $ to $;
  datalines;
n1, n3
n2, n3
n0, n4
n2, n5
n4, n7
n1, n8
n7, n8
n5, n9
n6, n9
;
