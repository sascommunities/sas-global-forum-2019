data sascas1.nodes;
  infile datalines dsd;
  length type $15.;
  input node type $;
  datalines;
0, GraduateStudent
1, Department
2, University
;

data sascas1.links;
  infile datalines dsd;
  length type $23.;
  input from to type $;
  datalines;
0, 1, .
0, 2, undergraduateDegreeFrom
1, 2, subOrganizationOf
;


proc cas;
	source myFilter;
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
		vars = (type);
	linksVar
		vars = (type);
	nodesQueryVar
		vars = (type);
	linksQueryVar
		vars = (type);
	patternMatch
		linkFilter = myLinkFilter
/*
		outMatchNodes = sascas1.OutMatchNodes
		outMatchLinks = sascas1.OutMatchLinks;
*/
;
run;