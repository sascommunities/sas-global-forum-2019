/* Below is the existing CASE statement (i.e. auto-matching algorithm) created by TPWD 
that creates RECON_DOC for the detailed expenditure reconciliation table (EXPENSE_FY_PR): 
*/
PROC SQL;
  CREATE TABLE LIBRARY.EXPENSE_FY_PR AS SELECT 
  /* RECON_DOC */
  (CASE
    WHEN t1.SOURCE = 'Projects-Miscellaneous Transaction' THEN t1.'REF_DOC'n 
    WHEN t1.SOURCE = 'BIS Only-CTX-Cash Transfer UB' & SUBSTR(t1.'CUR_DOC'n,1,2) = 'JF' & SUBSTR(t1.'REF_DOC'n,1,2) = 'JF' THEN t1.'REF_DOC'n /* Added 07-14-14 per KP*/ 
    WHEN t1.SOURCE = 'Projects-Usage Cost' THEN t1.'REF_DOC'n 
    WHEN t1.SOURCE = 'BIS Only-CTX-Cash Transfer In/Out' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'J' & SUBSTR(t1.'REF_DOC'n,1,1) = 'J' THEN t1.'REF_DOC'n /* Added 09-03-14 per KP*/ 
    WHEN t1.SOURCE = 'BIS Only-CTX-Cash Transfer In/Out' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'G' & SUBSTR(t1.'REF_DOC'n,1,1) = 'T' THEN t1.'REF_DOC'n /* Added 04-09-15 per KP*/ 
    WHEN t1.SOURCE = 'Payables-Purchase Invoices' & SUBSTR(t1.'CUR_DOC'n,1,2) = 'K0' & SUBSTR(t1.'REF_DOC'n,1,1) = 'T' THEN t1.'REF_DOC'n /* Added 01-08-15 per KP*/ 
    WHEN t1.SOURCE = 'Payables-Purchase Invoices' & SUBSTR(t1.'CUR_DOC'n,1,2) = 'K1' & SUBSTR(t1.'REF_DOC'n,1,1) = 'T' THEN t1.'REF_DOC'n /* Added 01-08-15 per KP*/ 
    WHEN t1.SOURCE = 'Payables-Purchase Invoices' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'G' & SUBSTR(t1.'REF_DOC'n,1,1) = 'T' THEN t1.'REF_DOC'n /* Added 09-04-14 per KP*/ 
    WHEN t1.SOURCE = 'Payables-Purchase Invoices' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'K' & SUBSTR(t1.'REF_DOC'n,1,1) = 'I' & t1.'CUR_SFX'n = '001' THEN t1.'REF_DOC'n /*Added 09-08-14 per KP*/ 
    WHEN t1.SOURCE = 'Payables-Purchase Invoices' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'J' & SUBSTR(t1.'REF_DOC'n,1,1) = 'J' THEN t1.'REF_DOC'n /* Added 01-08-15 per KP*/ 
    WHEN t1.SOURCE = 'Payables-Purchase Invoices' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'J' & SUBSTR(t1.'REF_DOC'n,1,1) = '9' THEN t1.'REF_DOC'n /* Added 05-12-16 per KP*/ 
    WHEN t1.SOURCE = 'Payables-Purchase Invoices' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'J' & SUBSTR(t1.'REF_DOC'n,1,1) = '2' THEN t1.'REF_DOC'n /* Added 05-12-16 per KP*/ 
    WHEN t1.SOURCE = 'Payables-Purchase Invoices' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'J' & SUBSTR(t1.'REF_DOC'n,1,1) = '1' THEN t1.'REF_DOC'n /* Added 05-12-16 per KP*/ 
    WHEN t1.SOURCE = 'Payables-Purchase Invoices' THEN t1.'CUR_DOC'n 
    WHEN t1.SOURCE = 'USAS' & t1.'REF_DOC'n LIKE 'BURDEN%' THEN t1.'REF_DOC'n 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'Y' THEN t1.'REF_DOC'n 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'C' THEN t1.'REF_DOC'n 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,2) = 'JF' & t1.'REF_DOC'n <> '' THEN t1.'REF_DOC'n /*Revised 02-24-16 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'J' & SUBSTR(t1.'REF_DOC'n,1,1) = 'J' THEN t1.'REF_DOC'n /* Added 12-30-14 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'J' & SUBSTR(t1.'REF_DOC'n,1,1) = '9' THEN t1.'REF_DOC'n /* Added 02-05-15 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'J' & SUBSTR(t1.'REF_DOC'n,1,1) = '2' THEN t1.'REF_DOC'n /* Added 02-05-15 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'J' & SUBSTR(t1.'REF_DOC'n,1,1) = '1' THEN t1.'REF_DOC'n /* Added 02-05-15 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,4) = 'G802' & SUBSTR(t1.'REF_DOC'n,1,1) = 'K' THEN t1.'REF_DOC'n /* Added 02-05-15 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'G' & t1.'REF_DOC'n = '' THEN t1.'CUR_DOC'n /* Added 03-12-15 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'G' & t1.'REF_DOC'n NOT = '' THEN t1.'REF_DOC'n /* Added 03-12-15 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,2) = 'KX' & SUBSTR(t1.'REF_DOC'n,1,1) = 'I' THEN t1.'REF_DOC'n /* Added 04-09-15 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,2) = 'KX' & SUBSTR(t1.'REF_DOC'n,1,1) = 'K' THEN t1.'REF_DOC'n /* Added 08-26-14 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,3) = 'KGL' & SUBSTR(t1.'REF_DOC'n,1,1) = '8' THEN t1.'REF_DOC'n /* Added 08-30-14 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,3) = 'KAP' & SUBSTR(t1.'REF_DOC'n,1,1) = '8' THEN t1.'REF_DOC'n /* Added 08-04-17 per AF*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,3) = 'KGL' & SUBSTR(t1.'REF_DOC'n,1,3) = 'KGL' THEN t1.'REF_DOC'n /* Added 01-08-15 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,3) = 'KAP' & SUBSTR(t1.'REF_DOC'n,1,3) = 'KAP' THEN t1.'REF_DOC'n /* Added 08-04-17 per AF*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,3) = 'KGL' & SUBSTR(t1.'REF_DOC'n,1,3) = 'W00' THEN t1.'REF_DOC'n /* Added 05-12-16 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,3) = 'KAP' & SUBSTR(t1.'REF_DOC'n,1,3) = 'W00' THEN t1.'REF_DOC'n /* Added 08-15-17 per AF*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'K' & SUBSTR(t1.'REF_DOC'n,1,1) = 'T' THEN t1.'REF_DOC'n /* Added 09-08-14 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'K' & SUBSTR(t1.'REF_DOC'n,1,1) = 'I' & t1.'CUR_SFX'n = '001' THEN t1.'REF_DOC'n /*Added 09-08-14 per KP*/ 
    WHEN t1.SOURCE = 'USAS' & SUBSTR(t1.'CUR_DOC'n,1,1) = 'K' & SUBSTR(t1.'REF_DOC'n,1,1) = 'I' & t1.'CUR_SFX'n <> '001' THEN t1.'CUR_DOC'n /*Added 09-08-14 per KP*/ 
    ELSE t1.'CUR_DOC'n 
    END)
  AS 'RECON_DOC'n, ETC., QUIT;