data sascas1.nodes;
  infile datalines dsd;
  input node;
  datalines;
0
1
2
;

data sascas1.links;
  infile datalines dsd;
  length type $11.;
  input from to type $;
  datalines;
0, 1, advisor
1, 2, teacherOf
0, 2, takesCourse
;



proc cas;
	source myFilter;
	function myNodeFilter(nodeQ, type $);
		if(nodeQ=0) then return (type='GraduateStudent' or type='UndergraduateStudent');
		if(nodeQ=1) then return (type='FullProfessor' or type='AssociateProfessor' or type='AssistantProfessor' or type='Lecturer');
		if(nodeQ=3) then return (type='Course' or type='GraduateCourse');
		else return (1);
	endsub;
	endsource;
	loadactionset "fcmpact";

	setSessOpt{cmplib="casuser.myRoutines"}; run;
	fcmpact.addRoutines /
		saveTable = true,
		funcTable = {name="myRoutines", caslib="casuser", replace=true},
		package = "myPackage",
		routineCode = myFilter;
	run;
quit;


proc network
        logLevel=aggressive
        direction=directed
        nThreads=&nThreads
	includeDuplicateLink
	links = sascas1.LinkSetIn
	nodes = sascas1.NodeSetIn
	nodesQuery = sascas1.Nodes
	linksQuery = sascas1.Links;
	nodesVar
		vars = (id type);
	linksVar
		vars = (type);
	linksQueryVar
		vars = (type);
	patternMatch
		nodeFilter = myNodeFilter
/*
		outMatchNodes = sascas1.OutMatchNodes
		outMatchLinks = sascas1.OutMatchLinks;*/
;
run;