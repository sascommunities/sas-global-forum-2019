data nodes;
  infile datalines dsd;
  length node $2. label $26.;
  input node $ label $;
  datalines;
n1,"Book: Health, Mind & Body"
n2,"Book: Parenting & Families"
n3,"Book: Children's Books"
n4,"Book: Home & Garden"
;

data links;
  infile datalines dsd;
  length from $2. to $2.;
  input from $ to $;
  datalines;
n1, n2
n2, n3
n4, n2
;
