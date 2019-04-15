ods path (prepend) work.templat(update);
proc template;
   define style styles.mystyle;
   parent = styles.word;
   class pageno /
     content = "Page {PAGE} of {NUMPAGES}"
     just = c
     vjust = b
   ;
   end;
run;
ods word file="c:\users\sasdck\onedrive - sas\topn2.docx" 
         options(keep_next="on") style=mystyle;
title "Top 10 Artists in Plays by Genre";
ods proclabel=" ";
proc print data=topn noobs contents="" label;
  by genre;
  var rank artist plays;
run;
ods word close;
title;

