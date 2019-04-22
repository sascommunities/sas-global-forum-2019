proc means data=myitunes sum noprint;
  var plays;
  class genre artist;
  output out=summary sum=plays genre /levels;
run;

proc sort data=summary out=topn;
  where _type_>2;
  by genre descending plays;
run;

data topn;
  length rank 8;
  label rank="Rank";
  set topn;
  by genre descending plays;
  if nmiss(of plays) then delete;
  if first.genre then rank=0;
  rank+1;
  if rank le 10 then output;
run;

ods word file="c:\users\sasdck\onedrive - sas\topn.docx" 
         options(contents="on" toc_data="on" keep_next="on");
title "Top 10 Artists in Plays by Genre";
ods proclabel=" ";
proc print data=topn noobs contents="" label;
  by genre;
  var rank artist plays;
run;
ods word close;
title;

