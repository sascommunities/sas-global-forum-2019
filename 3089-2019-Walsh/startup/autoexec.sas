/*********************************************************************************************************
DESCRIPTION: setup file to build the sas dataset for the exercises

INPUT:
in_dir = location where the csv file is located
out_lib = location where the sas dataset will reside

OUTPUT:
&out_lib..cas_crash.sas7bdat = crash analysis system sas7bdat file
&out_lib..cas_crash.csv = crash analysis system csv file (this has the target and a few dropped variables)

AUTHOR: EW

DEPENDENCIES:
NA

NOTES: 
Cross reference against one way tables to confirm data has been imported correctly

HISTORY: 
12 Feb 2019 EW updated after testing on image
18 Jan 2019 EW v1
*********************************************************************************************************/

/* setup variables */
libname how 'D:\Workshop\HOW';
%let in_path = D:\Workshop\HOW\data;     /* path to where the csv file is located */
%let out_lib = how;                 /* location where the sas dataset will reside */

data work.temp;
	length
		X                  8
		Y                  8
		OBJECTID           8
		crashYear          8
		crashFinancialYear $ 9
		crashSeverity    $ 1
		fatalCount         8
		seriousInjuryCount   8
		minorInjuryCount   8
		multiVehicle     $ 31
		holiday          $ 18
		regionDesc       $ 18
		tlaID              8
		tlaName          $ 30
		areaUnitID         8
		meshblockID        8
		easting            8
		northing           8
		crashLocation1   $ 25
		crashLocation2   $ 25
		outdatedLocationDescription $ 17
		crashRPRS          8
		intersection     $ 12
		junctionType     $ 15
		cornerRoadSideRoad   8
		crashDirectionDescription $ 5
		crashDistance      8
		crashRPDirectionDescription $ 10
		directionRoleDescription $ 7
		crashRPDisplacement   8
		crashSHDescription $ 3
		crashRPSH        $ 3
		crashRPNewsDescription $ 10
		intersectionMidblock $ 12
		flatHill         $ 7
		roadCharacter    $ 16
		roadCurvature    $ 14
		roadLane         $ 1
		roadMarkings     $ 16
		roadSurface      $ 8
		roadWet          $ 9
		numberOfLanes      8
		trafficControl   $ 14
		speedLimit       $ 3
		advisorySpeed      8
		temporarySpeedLimit   8
		urban            $ 8
		darkLight        $ 7
		light            $ 10
		streetLight      $ 7
		weatherA         $ 10
		weatherB         $ 11
		animals            8
		bridge             8
		cliffBank          8
		debris             8
		ditch              8
		fence              8
		guardRail          8
		houseBuilding      8
		kerb               8
		objectThrownOrDropped   8
		other              8
		overBank           8
		parkedVehicle      8
		phoneBoxEtc        8
		postOrPole         8
		roadworks          8
		slipFlood          8
		strayAnimal        8
		trafficIsland      8
		trafficSign        8
		train              8
		tree               8
		vehicle            8
		waterRiver         8
		bicycle            8
		bus                8
		carStationWagon    8
		moped              8
		motorcycle         8
		otherVehicleType   8
		schoolBus          8
		suv                8
		taxi               8
		truck              8
		unknownVehicleType   8
		vanOrUtility       8
		Pedestrian         8;
	format
		X                BEST19.
		Y                BEST19.
		OBJECTID         BEST6.
		crashYear        BEST4.
		crashFinancialYear $CHAR9.
		crashSeverity    $CHAR1.
		fatalCount       BEST1.
		seriousInjuryCount BEST2.
		minorInjuryCount BEST2.
		multiVehicle     $CHAR31.
		holiday          $CHAR18.
		regionDesc       $CHAR18.
		tlaID            BEST2.
		tlaName          $CHAR30.
		areaUnitID       BEST6.
		meshblockID      BEST7.
		easting          BEST7.
		northing         BEST7.
		crashLocation1   $CHAR25.
		crashLocation2   $CHAR25.
		outdatedLocationDescription $CHAR17.
		crashRPRS        BEST4.
		intersection     $CHAR12.
		junctionType     $CHAR15.
		cornerRoadSideRoad BEST1.
		crashDirectionDescription $CHAR5.
		crashDistance    BEST5.
		crashRPDirectionDescription $CHAR10.
		directionRoleDescription $CHAR7.
		crashRPDisplacement BEST5.
		crashSHDescription $CHAR3.
		crashRPSH        $CHAR3.
		crashRPNewsDescription $CHAR10.
		intersectionMidblock $CHAR12.
		flatHill         $CHAR7.
		roadCharacter    $CHAR16.
		roadCurvature    $CHAR14.
		roadLane         $CHAR1.
		roadMarkings     $CHAR16.
		roadSurface      $CHAR8.
		roadWet          $CHAR9.
		numberOfLanes    BEST1.
		trafficControl   $CHAR14.
		speedLimit       $CHAR3.
		advisorySpeed    BEST2.
		temporarySpeedLimit BEST2.
		urban            $CHAR8.
		darkLight        $CHAR7.
		light            $CHAR10.
		streetLight      $CHAR7.
		weatherA         $CHAR10.
		weatherB         $CHAR11.
		animals          BEST1.
		bridge           BEST1.
		cliffBank        BEST1.
		debris           BEST1.
		ditch            BEST1.
		fence            BEST1.
		guardRail        BEST1.
		houseBuilding    BEST1.
		kerb             BEST1.
		objectThrownOrDropped BEST1.
		other            BEST1.
		overBank         BEST1.
		parkedVehicle    BEST1.
		phoneBoxEtc      BEST1.
		postOrPole       BEST1.
		roadworks        BEST1.
		slipFlood        BEST1.
		strayAnimal      BEST1.
		trafficIsland    BEST1.
		trafficSign      BEST1.
		train            BEST1.
		tree             BEST1.
		vehicle          BEST1.
		waterRiver       BEST1.
		bicycle          BEST1.
		bus              BEST1.
		carStationWagon  BEST2.
		moped            BEST1.
		motorcycle       BEST1.
		otherVehicleType BEST1.
		schoolBus        BEST1.
		suv              BEST1.
		taxi             BEST1.
		truck            BEST1.
		unknownVehicleType BEST1.
		vanOrUtility     BEST1.
		Pedestrian       BEST1.;
	informat
		X                BEST19.
		Y                BEST19.
		OBJECTID         BEST6.
		crashYear        BEST4.
		crashFinancialYear $CHAR9.
		crashSeverity    $CHAR1.
		fatalCount       BEST1.
		seriousInjuryCount BEST2.
		minorInjuryCount BEST2.
		multiVehicle     $CHAR31.
		holiday          $CHAR18.
		regionDesc       $CHAR18.
		tlaID            BEST2.
		tlaName          $CHAR30.
		areaUnitID       BEST6.
		meshblockID      BEST7.
		easting          BEST7.
		northing         BEST7.
		crashLocation1   $CHAR25.
		crashLocation2   $CHAR25.
		outdatedLocationDescription $CHAR17.
		crashRPRS        BEST4.
		intersection     $CHAR12.
		junctionType     $CHAR15.
		cornerRoadSideRoad BEST1.
		crashDirectionDescription $CHAR5.
		crashDistance    BEST5.
		crashRPDirectionDescription $CHAR10.
		directionRoleDescription $CHAR7.
		crashRPDisplacement BEST5.
		crashSHDescription $CHAR3.
		crashRPSH        $CHAR3.
		crashRPNewsDescription $CHAR10.
		intersectionMidblock $CHAR12.
		flatHill         $CHAR7.
		roadCharacter    $CHAR16.
		roadCurvature    $CHAR14.
		roadLane         $CHAR1.
		roadMarkings     $CHAR16.
		roadSurface      $CHAR8.
		roadWet          $CHAR9.
		numberOfLanes    BEST1.
		trafficControl   $CHAR14.
		speedLimit       $CHAR3.
		advisorySpeed    BEST2.
		temporarySpeedLimit BEST2.
		urban            $CHAR8.
		darkLight        $CHAR7.
		light            $CHAR10.
		streetLight      $CHAR7.
		weatherA         $CHAR10.
		weatherB         $CHAR11.
		animals          BEST1.
		bridge           BEST1.
		cliffBank        BEST1.
		debris           BEST1.
		ditch            BEST1.
		fence            BEST1.
		guardRail        BEST1.
		houseBuilding    BEST1.
		kerb             BEST1.
		objectThrownOrDropped BEST1.
		other            BEST1.
		overBank         BEST1.
		parkedVehicle    BEST1.
		phoneBoxEtc      BEST1.
		postOrPole       BEST1.
		roadworks        BEST1.
		slipFlood        BEST1.
		strayAnimal      BEST1.
		trafficIsland    BEST1.
		trafficSign      BEST1.
		train            BEST1.
		tree             BEST1.
		vehicle          BEST1.
		waterRiver       BEST1.
		bicycle          BEST1.
		bus              BEST1.
		carStationWagon  BEST2.
		moped            BEST1.
		motorcycle       BEST1.
		otherVehicleType BEST1.
		schoolBus        BEST1.
		suv              BEST1.
		taxi             BEST1.
		truck            BEST1.
		unknownVehicleType BEST1.
		vanOrUtility     BEST1.
		Pedestrian       BEST1.;
	infile "&in_path./Crash_Analysis_System_CAS_data.csv"
		lrecl=520
		firstobs=2
		encoding="UTF-8"
		dlm='2c'x
		missover
		dsd;
	input
		X                : ?? COMMA19.
		Y                : ?? COMMA19.
		OBJECTID         : ?? BEST6.
		crashYear        : ?? BEST4.
		crashFinancialYear : $CHAR9.
		crashSeverity    : $CHAR1.
		fatalCount       : ?? BEST1.
		seriousInjuryCount : ?? BEST2.
		minorInjuryCount : ?? BEST2.
		multiVehicle     : $CHAR31.
		holiday          : $CHAR18.
		regionDesc       : $CHAR18.
		tlaID            : ?? BEST2.
		tlaName          : $CHAR30.
		areaUnitID       : ?? BEST6.
		meshblockID      : ?? BEST7.
		easting          : ?? BEST7.
		northing         : ?? BEST7.
		crashLocation1   : $CHAR25.
		crashLocation2   : $CHAR25.
		outdatedLocationDescription : $CHAR17.
		crashRPRS        : ?? BEST4.
		intersection     : $CHAR12.
		junctionType     : $CHAR15.
		cornerRoadSideRoad : ?? BEST1.
		crashDirectionDescription : $CHAR5.
		crashDistance    : ?? BEST5.
		crashRPDirectionDescription : $CHAR10.
		directionRoleDescription : $CHAR7.
		crashRPDisplacement : ?? BEST5.
		crashSHDescription : $CHAR3.
		crashRPSH        : $CHAR3.
		crashRPNewsDescription : $CHAR10.
		intersectionMidblock : $CHAR12.
		flatHill         : $CHAR7.
		roadCharacter    : $CHAR16.
		roadCurvature    : $CHAR14.
		roadLane         : $CHAR1.
		roadMarkings     : $CHAR16.
		roadSurface      : $CHAR8.
		roadWet          : $CHAR9.
		numberOfLanes    : ?? BEST1.
		trafficControl   : $CHAR14.
		speedLimit       : $CHAR3.
		advisorySpeed    : ?? BEST2.
		temporarySpeedLimit : ?? BEST2.
		urban            : $CHAR8.
		darkLight        : $CHAR7.
		light            : $CHAR10.
		streetLight      : $CHAR7.
		weatherA         : $CHAR10.
		weatherB         : $CHAR11.
		animals          : ?? BEST1.
		bridge           : ?? BEST1.
		cliffBank        : ?? BEST1.
		debris           : ?? BEST1.
		ditch            : ?? BEST1.
		fence            : ?? BEST1.
		guardRail        : ?? BEST1.
		houseBuilding    : ?? BEST1.
		kerb             : ?? BEST1.
		objectThrownOrDropped : ?? BEST1.
		other            : ?? BEST1.
		overBank         : ?? BEST1.
		parkedVehicle    : ?? BEST1.
		phoneBoxEtc      : ?? BEST1.
		postOrPole       : ?? BEST1.
		roadworks        : ?? BEST1.
		slipFlood        : ?? BEST1.
		strayAnimal      : ?? BEST1.
		trafficIsland    : ?? BEST1.
		trafficSign      : ?? BEST1.
		train            : ?? BEST1.
		tree             : ?? BEST1.
		vehicle          : ?? BEST1.
		waterRiver       : ?? BEST1.
		bicycle          : ?? BEST1.
		bus              : ?? BEST1.
		carStationWagon  : ?? BEST2.
		moped            : ?? BEST1.
		motorcycle       : ?? BEST1.
		otherVehicleType : ?? BEST1.
		schoolBus        : ?? BEST1.
		suv              : ?? BEST1.
		taxi             : ?? BEST1.
		truck            : ?? BEST1.
		unknownVehicleType : ?? BEST1.
		vanOrUtility     : ?? BEST1.
		Pedestrian       : ?? BEST1.;
run;


/* make sure the variables perfectly correlated with the target are removed along with
any ids and geographic info such as latitude and longitude */
data &out_lib..cas_crash (drop = crashSeverity fatalcount seriousinjurycount minorinjurycount
x y easting northing crashlocation1 crashlocation2 outdatedlocationdescription
crashyear crashfinancialyear areaunitid meshblockid tlaid);
	set work.temp;

	if(crashSeverity in ('F','S')) then
		target = 1; else target = 0;
run;

/* create a new csv version that can be used in the RStudio exercises */
proc export data = how.cas_crash outfile = "&in_path./cas_crash.csv" dbms = csv replace;
run;

/* check that you get consistent results as the html output */
proc freq data = &out_lib..cas_crash
	order = internal
;
    tables target / scores =  table;
	tables bridge /  scores = table;
	tables cliffbank /  scores = table;
	tables debris /  scores = table;
	tables ditch /  scores = table;
	tables fence /  scores = table;
	tables guardrail /  scores = table;
	tables housebuilding /  scores = table;
	tables kerb /  scores = table;
	tables objectthrownordropped /  scores = table;
	tables other /  scores = table;
	tables overbank /  scores = table;
	tables parkedvehicle /  scores = table;
	tables phoneboxetc /  scores = table;
	tables postorpole /  scores = table;
	tables roadworks /  scores = table;
	tables slipflood /  scores = table;
	tables strayanimal /  scores = table;
	tables trafficisland /  scores = table;
	tables trafficsign /  scores = table;
	tables train /  scores = table;
	tables tree /  scores = table;
	tables vehicle /  scores = table;
	tables waterriver /  scores = table;
	tables bicycle /  scores = table;
	tables bus /  scores = table;
	tables carstationwagon /  scores = table;
	tables moped /  scores = table;
	tables motorcycle /  scores = table;
	tables othervehicletype /  scores = table;
	tables schoolbus /  scores = table;
	tables suv /  scores = table;
	tables taxi /  scores = table;
	tables truck /  scores = table;
	tables unknownvehicletype /  scores = table;
	tables vanorutility /  scores = table;
	tables pedestrian /  scores = table;
run;

