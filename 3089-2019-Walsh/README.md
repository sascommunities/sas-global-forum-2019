# Working with both Proprietary and Open Source Software (3089)
In 2018, Ernestynne delivered one of the top-rated presentations at the SAS® Users New Zealand conference. The presentation talked about a future of working with both open-source and proprietary software. It covered the benefits and provided some examples of combining both. The future is now here. This 90-minute Hands-On Workshop drills down into examples that were briefly touched on during that presentation. Attendees get a taste of working with R in SAS® Enterprise Miner™ and some general best practice tips. There is an introduction to the Scripting Wrapper for Analytics Transfer (SWAT) package, which enables you to interface with SAS® Viya® in open-source languages like R. This presentation briefly covers avoiding some traps that you can fall into when working with the SWAT package. The techniques learned here can be extended to enable you to work with Python in SAS®. The emphasis of this Hands-On Workshop is how to combine SAS with open-source tools, rather than teaching attendees how to code in R.

### To get in touch
Ernestynne Walsh
+64272812147
ernestynne@nicholsonconsulting.co.nz

### Licenses
#### Dataset
This work is based on/includes NZTA data retrieved from data.govt.nz which is hosted and operated by the DIA. It is licensed for re-use under the Creative Commons Attribution 4.0 International licence.

For more information see
https://www.data.govt.nz/terms-of-use/

#### Code Base
GNU GPLv3

Copyright Ernestynne Walsh, Nicholson Consulting (C) 2018. 

See LICENSE.md for more details

#### Other Content
Copyright Ernestynne Walsh, Nicholson Consulting (C) 2018. 

[![License: CC BY 4.0](https://i.creativecommons.org/l/by/4.0/88x31.png)](https://creativecommons.org/licenses/by/4.0/)

This copyright work is licensed under the Creative Commons Attribution 4.0 International licence. In essence, you are free to copy, distribute and adapt the work, as long as you attribute the work to Ernestynne Walsh, Nicholson Consulting and abide by the other licence terms. 

To view a copy of this licence, visit [http://creativecommons.org/licenses/by/4.0/](http://creativecommons.org/licenses/by/4.0/). 

### File Structure
| Subdirectory  | Filename         | Description
| ------------- | -------------    |--------------
| .             | .gitignore       | File types excluding from version control (datasets, MS Office files etc)
| .             | LICENSE.md       | Licensing info for the code base
| .             | README.md        | Markdown file explaining requirements, installation and known issues
| .             | how-slides.pdf   | Slide deck containing content for the workshop
| .             | intro-pres.pdf   | Slide deck to introduce the motivation for this workshop
| .             | notes-exercise-viya.pdf  | Notes and exercises for the Viya, R and swat package part of the workshop
| .             | notes-exercises-enterprise-miner.pdf  | Notes and exercises for the Enterprise Miner part of the workshop
|./data         | CAS-metadata.txt | location of datasource, metadata and overview of the dataset
|./exercises    | Ex-1.xml         | Enterprise Miner Diagram for the first exercise
|./exercises    | Ex-2-3-Helper.txt| List of macro variables that can be used in the second exercise
|./exercises    | Ex-2-3.xml       | Enterprise Miner Diagram used for the second and third exercises
|./exercises    | Ex-4.R           | R script used for the fourth exercise
|./results      | Ex-1.out         | Output for exercise 1 (note there is no output so this file is blank)
|./results      | Ex-2.out         | Output of just the open source integration node (not the whole diagram)
|./results      | Ex-3.out         | Output of just the model import node (not the whole diagram)
|./results      | Ex-4.out         | Console output for exercise 4
|./solutions    | Ex-1-Solution.xml | Enterprise Miner diagram solution for the first exercise
|./solutions    | Ex-1.log         | Enterprise Miner result log for Exercise 1
|./solutions    | Ex-2-3-Solution.xml | Enterprise Miner diagram solution for the second and third exercise
|./solutions    | Ex-2.log         | Log of just the open source integration node (not the whole diagram)
|./solutions    | Ex-3.log         | Log of the model import node (not the whole diagram)
|./solutions    | Ex-4-Solution.R  | Completed R script covering all the solutions for the fourth exercise
|./solutions    | Ex-4.log         | Console output for exercise 4
|./startup      | autoexec.sas     | Script used to build the dataset and includes tests
|./startup      | autoexec.html    | Test output
|./startup      | autoexec.log     | Log output

### Requirements
**Images and software**
This workshop has been tested on the following images and software

*** Enterprise Miner ***
Software Version: SAS 9.4 M4, EM 14.2
Image Name: EDU\_EM\_FS94M4

*** R Studio and R ***
Software Version: R Studio 1.1.456, R 3.5.1 "Feather Spray"
Image Name: EDU_Viya33Analytics

**** R packages ****
randomForest (4.6-12)
swat (1.3.0)

as well as all their dependencies

**Other**
Internet access so that attendees can look at the online data dictionary

### Known Issues
1. The authinfo file is not populated on EDU_Viya33Analytics
2. Originally, `./exercises/Ex-2-3.xml` had the solution in the Code Editor of the open source integration node. This has been fixed by directly editing the xml file but has not been tested during a diagram import into Enterprise Miner. If this causes issues then the original xml file can be retrieved from[https://github.com/nicholson-consulting/sgf-workshop/blob/4172faf691bb5652e3d84af60ae7312cabf5b331/exercises/Ex-2-3.xml](here). The EM project submit text file code has also been updated.

### Installation
1. Create the directory `D:/Workshop/HOW`
2. Create file `D:/Workshop/HOW/data/cas_crash.csv` this can be done using the link in `./data/CAS-metadata.txt` or accessing the zipped csv file if you access to it. Warning using the link means that you will have the latest version of the data not the version that the workshop was built on
3. Run `./startup/autoexec.sas` and confirm that the output you get is the same as `./startup/autoexec.html`
4. Open up `./solutions/Ex-4-Solution.R`, read the dependencies and notes. Once you have sorted out the dependencies and the notes you can run the script and confirm that you get `./results/Ex-4.out`
5. An Enterprise Miner Project is required. A zipped EM project can be provided on request in which case carry on at step 10. Alternatively, one can be created from scratch by following the subsequent steps
6. Create the EM Project. The project name is `HOW-Open-Source-Integration`, directory is `D:/Workshop/HOW`, the default metadata server and default application server can be used
7. Create a library called `how` that points to `D:/Workshop/HOW/data`
8. Create the data source. The file you will choose is `cas_crash.sas7bdat` use all the default settings up to step 4. At step 4 check the `advanced` metadata option. At step 5 you will need to change the role of `OBJECTID` to an `ID` then you can accept all the other defaults and hit next until you can hit finish
9. Import the diagrams `./exercises/Ex-1.xml`, `./solutions.Ex-1-Solution.xml`, `./exercises/Ex-2-3.xml` and `./solutions/Ex-2-3-Solution.xml`
10. Open `./solutions/Ex-1-Solution.xml` and run the diagram. Confirm that you get the results listed in `./solutions/Ex-1.log`
11. Open `./solutions/Ex-2-3-Solution.xml` and run the diagram. Confirm that you get the results listed in `./solutions/Ex-2.log` and `./solutions/Ex-3.log`
12. Open `./exercises/Ex-2-3.xml` and run the nodes **prior** to the R randomForest open source integration node




