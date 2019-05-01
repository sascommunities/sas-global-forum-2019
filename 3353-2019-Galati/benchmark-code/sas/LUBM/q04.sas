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
  length type $8.;
  input from to type $;
  datalines;
0, 1, worksFor
;


proc cas;
	source myFilter;
	function myNodeFilter(nodeQ, type $);
		if(nodeQ=0) then return (type='FullProfessor' or type='AssociateProfessor' or type='AssistantProfessor');
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
	linksQueryVar
		vars = (type);
	patternMatch
		nodeFilter = myNodeFilter
/*		outMatchNodes = sascas1.OutMatchNodes
		outMatchLinks = sascas1.OutMatchLinks;*/
;
run;