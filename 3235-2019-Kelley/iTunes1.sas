 /**********************************************************************
 *   PRODUCT:   SAS
 *   VERSION:   9.4
 *   CREATOR:   External File Interface
 *   DATE:      09NOV18
 *   DESC:      Generated SAS Datastep Code
 *   TEMPLATE SOURCE:  (None Specified.)
 ***********************************************************************/
    data SASUSER.ITUNES    ;
    %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
    infile 'test/iTunesPlaylist.txt' delimiter='09'x MISSOVER DSD lrecl=32767 firstobs=2 ;
       informat Name $456. ;
       informat Artist $255. ;
       informat Composer $118. ;
       informat Album $95. ;
       informat Grouping best32. ;
       informat Work best32. ;
       informat Movement_Number best32. ;
       informat Movement_Count best32. ;
       informat Movement_Name $17. ;
       informat Genre $18. ;
       informat Size best32. ;
       informat Time best32. ;
       informat Disc_Number best32. ;
       informat Disc_Count best32. ;
       informat Track_Number best32. ;
       informat Track_Count best32. ;
       informat Year $4. ;
       informat Date_Modified anydtdtm40. ;
       informat Date_Added anydtdtm40. ;
       informat Bit_Rate best32. ;
       informat Sample_Rate best32. ;
       informat Volume_Adjustment $147. ;
       informat Kind $27. ;
       informat Equalizer anydtdtm40. ;
       informat Comments $29. ;
       informat Plays best32. ;
       informat Last_Played anydtdtm40. ;
       informat Skips best32. ;
       informat Last_Skipped anydtdtm40. ;
       informat My_Rating $123. ;
       informat Location $152. ;
       format Name $456. ;
       format Artist $255. ;
       format Composer $118. ;
       format Album $95. ;
       format Grouping best12. ;
       format Work best12. ;
       format Movement_Number best12. ;
       format Movement_Count best12. ;
       format Movement_Name $17. ;
       format Genre $18. ;
       format Size best12. ;
       format Time mmss. ;
       format Disc_Number best12. ;
       format Disc_Count best12. ;
       format Track_Number best12. ;
       format Track_Count best12. ;
       format Year $4. ;
       format Date_Modified datetime. ;
       format Date_Added datetime. ;
       format Bit_Rate best12. ;
       format Sample_Rate best12. ;
       format Volume_Adjustment $147. ;
       format Kind $27. ;
       format Equalizer datetime. ;
       format Comments $29. ;
       format Plays best12. ;
       format Last_Played datetime. ;
       format Skips best12. ;
       format Last_Skipped datetime. ;
       format My_Rating $123. ;
       format Location $152. ;
    input
                Name  $
                Artist  $
                Composer  $
                Album  $
                Grouping
                Work
                Movement_Number  $
                Movement_Count
                Movement_Name  $
                Genre  $
                Size
                Time
                Disc_Number
                Disc_Count  $
                Track_Number  $
                Track_Count  $
                Year  $
                Date_Modified  $
                Date_Added  $
                Bit_Rate  $
                Sample_Rate
                Volume_Adjustment  $
                Kind  $
                Equalizer
                Comments  $
                Plays
                Last_Played
                Skips
                Last_Skipped
                My_Rating  $
                Location  $
    ;
    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
    run;
