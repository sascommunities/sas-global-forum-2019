data sascas1.nodes;
  infile datalines dsd;
  input node;
  datalines;
0
;


proc cas;
	source myFilter;
	function myNodeFilter(nodeQ, type $);
		if(nodeQ=0) then return (type='GraduateStudent' or type='UndergraduateStudent');
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
	links = sascas1.LinkSetIn
	nodes = sascas1.NodeSetIn
	nodesQuery = sascas1.Nodes;
	nodesVar
		vars = (type);
	patternMatch
		nodeFilter = myNodeFilter
/*
		outMatchNodes = sascas1.OutMatchNodes
		outMatchLinks = sascas1.OutMatchLinks;*/
;
run;