# SAS  Viya  reportImages Service: The Report Optimization Speedometer - SAS Code     

## All code included in this section must be submitted in a SAS Studio 5.1 (or later) session within a Viya 3.4 (or later) environment which contains the SAS Viya services that are being called.

This paper demonstrates two main SAS Code examples which interact with the SAS Viya APIs.  Before running these code examples both the SAS Visual Analytics example reports and their associated data soruces will need to be generated/imported into your SAS Viya platform.  This can be accomplished by first completing the steps in the [data](../Data/README.md) and [Visual Analytics Reports](../Data/Visual Analytics Reports/README.md) sections of this GitHub repository.


The two SAS Code examples are below:

[create_VA_svg_image.sas](./create_VA_svg_image.sas)
* This program contains a macro which is fed a SAS Visual Analytics Report's UID as a parameter.  The macro will request the SAS Viya reportImages service create an SVG image of the requested report.  The output image is then displayed in the SAS Studio 5.1 results window.

[Report_Optimization_Speedometer.sas](./Report_Optimization_Speedometer.sas)
* This program contains a macro which is fed a SAS Visual Analytics report's data source (as a sashdat file), the report's name and the report's UID as parameters.  The macro will first refresh the report's data source in CAS.  After the data refresh the SAS Viya reportImages service us used to create an SVG image of the requested report.  Upon completing the creating the SVG file the total duration of the image's duration time is recorded and printed.  
* This macro can be called several times for either the same or multiple reports.



