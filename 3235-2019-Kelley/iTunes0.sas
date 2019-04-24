proc import datafile="test/iTunesPlaylist.txt" dbms=tab out=sasuser.iTunes replace;
   getnames=yes;
   guessingrows=3000;
run;   
