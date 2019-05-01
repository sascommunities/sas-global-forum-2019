data sascas1.nodes;
  infile datalines dsd;
  length id $11. type $13.;
  input node id $ type $;
  datalines;
0, ., FullProfessor
1, ., Department
2, University0, .
;

data sascas1.links;
  infile datalines dsd;
  length type $17.;
  input from to type $;
  datalines;
0, 1, worksFor
1, 2, subOrganizationOf
0, 1, headOf
;


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
	nodesQueryVar
		vars = (id type);
	linksVar
		vars = (type);
	linksQueryVar
		vars = (type);
	patternMatch
/*
		outMatchNodes = sascas1.OutMatchNodes
		outMatchLinks = sascas1.OutMatchLinks;*/
;
run;