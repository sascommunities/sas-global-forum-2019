Contents:
========

This ZIP archive contains the following files for use with the SAS Global Forum 2019 workshop
"Integrating SAS and Microsoft Excel: Exploring the Many Options Available to You"
Vincent DelGobbo, SAS Institute Inc.

SAS2991-2019.pdf - Paper that appears in the SAS Global Forum proceedings.

DelGobbo_Excel_2019_Handout.pdf - One-page handout with basic information.

DelGobbo_Excel_2019_HOW.pdf - Annotated slides and step-by-step instructions.

LabResults.csv - Comma-separated value file to import.

LabResults.xlsx - Microsoft Excel workbook to import.

LabResults.sas7bdat - SAS data set to export.

Exercise1a.sas - Import a CSV file using PROC IMPORT (Base SAS).

Exercise1b.sas - Import a CSV file with special characters in variable names using PROC IMPORT (Base SAS).

Exercise2.sas - Retrieve and view DATA step code to import a CSV file (Base SAS).

Exercise3.sas - Import a single worksheet from an XLSX file using PROC IMPORT (SAS/ACCESS).

Exercise4.sas - Import a single worksheet from an XLSX file using the DATA step and the XLSX libname engine (SAS/ACCESS).

Exercise5.sas - Import all worksheets from an XLSX file using PROC DATASETS and the XLSX libname engine (SAS/ACCESS).

Exercise6a.sas - Export a SAS data set to a multi-sheet XLSX file using the ODS EXCEL destination (Base SAS).

Exercise6b.sas - Export a SAS data set to a multi-sheet XLSX file and apply an Excel number format using the ODS EXCEL destination (Base SAS).

Exercise7.sas - Export a SAS data set to a single worksheet of an XLSX file using PROC EXPORT (SAS/ACCESS).

Exercise8.sas - Export multiple SAS data sets to a multi-sheet XLSX file using PROC DATASETS and the XLSX libname engine (SAS/ACCESS).

Setup.sas - Set up the SAS operating environment.

Solution1b.sas - Solution to Exercise1b.

Solution3.sas - Solution to Exercise3.

Solution4.sas - Solution to Exercise4.

Solution5.sas - Solution to Exercise5.

Solution6b.sas - Solution to Exercise6b.

Solution7.sas - Solution to Exercise7.

ReadMe.txt - This file.


Installation:
============

The sample SAS code assumes that you have extracted the archive into the directory "C:\HOW\DelGobbo\".  If you extract this archive to a different directory, you must to modify the value of the PATH macro variable in the Setup.sas file.

Additionally, all SAS output is written to this directory.


Usage:
=====

Start SAS and submit Setup.sas, followed by the other files of interest.