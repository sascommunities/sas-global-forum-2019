data sascas1.nodes;
  infile datalines dsd;
  length id $11.;
  input node id $;
  datalines;
0, .
1, University0
;

data sascas1.links;
  infile datalines dsd;
  input from to;
  datalines;
0, 1
;

proc cas;
	source myFilter;
	function myLinkFilter(fromQ, toQ, type $);
		if(fromQ=0 and toQ=1) then return (type='doctoralDegreeFrom' or type='mastersDegreeFrom' or type='undergraduateDegreeFrom');
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
		vars = (id);
	nodesQueryVar
		vars = (id);
	linksVar
		vars = (type);
	patternMatch
		linkFilter = myLinkFilter
/*
		outMatchNodes = sascas1.OutMatchNodes
		outMatchLinks = sascas1.OutMatchLinks;*/
;
run;