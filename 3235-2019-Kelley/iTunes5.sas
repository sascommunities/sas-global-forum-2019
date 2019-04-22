ods word file="c:\users\sasdck\onedrive - sas\genres2.docx";
title "My iTunes Genres";
proc tabulate data=myitunes;
  class genre;
  table genre="" all="Total", n="Tracks" colpctn="%"/box="Genre";
run;
ods word close;
title;
