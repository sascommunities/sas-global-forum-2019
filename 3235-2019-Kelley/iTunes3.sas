options nodate nonumber;
ods word file="iTunes0a.docx" title="iTunes Metadata";
*title "iTunes Metadata";
title;
ods select attributes variables;
proc contents data=myitunes;
run;
ods word close;   
title;   
options date number;
   
