proc sort data=myitunes(keep=album genre where=(genre="Soundtrack")) 
          out=soundtracks nodupkey;
   by album;
run;

ods word file="c:\users\sasdck\onedrive - sas\soundtracks.docx";
title "My iTunes Soundtracks";
proc odslist data=soundtracks;
   item put(album,$95.)/style={liststyletype=decimal};
run;
ods word close; 
title;
