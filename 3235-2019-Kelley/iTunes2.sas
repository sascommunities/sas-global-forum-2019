ods word file="c:\users\sasdck\onedrive - sas\genres.docx";
title "My iTunes Genres";
proc sgpie data=myitunes;
  pie genre / datalabeldisplay=(percent);
run;
ods word close;
title;
