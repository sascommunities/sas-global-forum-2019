data sascas1.nodes;
  infile datalines dsd;
  length id $23. type $10.;
  input node id $ type $;
  datalines;
0, ., .
1, Department0.University0, Department
;

data sascas1.links;
  infile datalines dsd;
  input from to;
  datalines;
0, 1
;



proc cas;
	source myFilter;
/*	function myNodeFilter(nodeQ, type $);
		if(nodeQ=0) then return (type='FullProfessor' or type='AssociateProfessor' or type='AssistantProfessor' or type='Lecturer' or type='GraduateStudent' or type='UndergraduateStudent');
		else return (1);
	endsub;
*/
	function myNodeFilter(nodeQ, type $);
		if(nodeQ=0) then return (type in ('FullProfessor','AssociateProfessor','AssistantProfessor','Lecturer','GraduateStudent','UndergraduateStudent'));
		else return (1);
	endsub;
	function myLinkFilter(fromQ, toQ, type $);
		if(fromQ=0 and toQ=1) then return (type='worksFor' or type='memberOf');
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
	nodesQueryVar
		vars = (id type);
	patternMatch
		nodeFilter = myNodeFilter
		linkFilter = myLinkFilter
/*
		outMatchNodes = sascas1.OutMatchNodes
		outMatchLinks = sascas1.OutMatchLinks;*/
;
run;