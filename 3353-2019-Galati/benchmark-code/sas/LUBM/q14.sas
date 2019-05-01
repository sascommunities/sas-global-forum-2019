data sascas1.nodes;
  infile datalines dsd;
  length node type $20.;
  input node type $;
  datalines;
0, UndergraduateStudent
;


proc network
        logLevel=aggressive
        direction=directed
        nThreads=&nThreads
	includeDuplicateLink
	links = sascas1.LinkSetIn
	nodes = sascas1.NodeSetIn
	nodesQuery = sascas1.Nodes;
	nodesVar
		vars = (type);
	nodesQueryVar
		vars = (type);
	patternMatch
/*
		outMatchNodes = sascas1.OutMatchNodes
		outMatchLinks = sascas1.OutMatchLinks;*/
;
run;