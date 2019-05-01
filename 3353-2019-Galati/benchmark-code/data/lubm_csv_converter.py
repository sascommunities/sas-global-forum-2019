"""
Converts the LUBM RDF data to csv files.
Can convert into format for batch insert into Neo4j.

Generally, given an S,P,O triple, 
    - if O is a literal, it becomes a property/attribute of node S.
    - else, node S links to node O on edge with label P.

For more information on RDF->property graph, see here: https://jbarrasa.com/2016/06/07/importing-rdf-data-into-neo4j/
"""

import os
import glob
import argparse
import rdflib

parser = argparse.ArgumentParser(description="Generates synthetic graph")
parser.add_argument("dir", help="Path to folder containing raw LUBM .owl files")
parser.add_argument("--neo4j",  help="Neo4j output style (separate header files)", action="store_true")
args = parser.parse_args()


# RDFLIB adds abstract node representing the ontology, which we do not want
# So we make sure to not take the ontology URI as a node
ONTOLOGY_URI = rdflib.URIRef("http://www.w3.org/2002/07/owl#Ontology")
RA_URI       = rdflib.URIRef("http://swat.cse.lehigh.edu/onto/univ-bench.owl#ResearchAssistant")
TA_URI       = rdflib.URIRef("http://swat.cse.lehigh.edu/onto/univ-bench.owl#TeachingAssistant")


# Functions for cleaning up URIs
def strip_id_uri(uri):
    string = str(uri)
    string = string.replace("http://www.", "")
    string = string.replace(".edu", "")
    string = string.replace("/", ".")
    return string
def strip_prop_uri(uri):
    return str(uri).rsplit("#",1)[-1]


# Load the RDF data
g = rdflib.Graph()
for f in sorted(glob.glob(args.dir+ "/*.owl")):
    print(f)
    g.parse(f)


# Get properties (attributes) and number of vertices
props = set()
for s,p,o in g:
    # If o is a literal, p is a a property with o as the value
    # If p is rdf:type, then o becomes a node label (not a property) in Neo4j
    if (type(o) == rdflib.term.Literal or (not args.neo4j and p == rdflib.namespace.RDF.type)):
        props.add(p)

ordered_props = sorted(props, key=lambda p: strip_prop_uri(p))
prop_to_idx = {p:i for i,p in enumerate(ordered_props)}


# Open node and link files
linkfile = open("links.csv", "w")
nodefile = open("nodes.csv", "w")

# Write header in CSV file (it not Neo4j output style, which uses separate file)
if not args.neo4j:
    nodefile.write("node,id")
    for p in ordered_props:
        nodefile.write(","+strip_prop_uri(p))
    nodefile.write("\n")

    linkfile.write("from,to,type\n")

# Create header files for Neo4j
if args.neo4j:
    with open("nodes_header.csv", "w") as fout:
        fout.write(":ID,id")
        for p in ordered_props:
            fout.write(","+strip_prop_uri(p))
        fout.write(",:LABEL\n")
    
    with open("links_header.csv", "w") as fout:
        fout.write(":START_ID,:END_ID,:TYPE\n")


# ----
# Loop over RDF graph to determine links and properties of nodes
# Output to file as we go
# ----
nodeid = {} # maps URI of subject or object to integer node IDs
triple_count = 0
subjects_visited = set([])
for s in g.subjects():
    if s in subjects_visited or "file://" in str(s):
        # g.subjects() does not give unique, so check if already visited
        # Also remove abstract file nodes rdflib creates
        continue
    subjects_visited.add(s)
    
    start_id = strip_id_uri(s)
    
    if not start_id in nodeid:
        nodeid[start_id] = str(len(nodeid))

    vals = [""]*(len(props))
    labels = ""
    for p,o in g.predicate_objects(s):
        if o == ONTOLOGY_URI or o == RA_URI or o == TA_URI:
            # Remove abstract nodes rdflib creates referring to ontology file
            # Remove RA and TA types as not used in query and creating overlapping labels
            continue
        elif args.neo4j and p == rdflib.namespace.RDF.type:
            # Predicate is rdf:type, which we make into a label
            # Multiple labels can exist (e.g., GraudateStudent and TA), so we append if needed
            if len(labels) > 0:
                labels += ";"
            labels += strip_prop_uri(o)
        elif type(o) == rdflib.term.Literal or p == rdflib.namespace.RDF.type:
            # Object is a literal, so predicate P becomes a node property with value O
            # or P is an rdf:type relationship and we want types to be properties (not labels)
            vals[prop_to_idx[p]] = strip_prop_uri(o)
        else:
            # We have a relationship (link)
            end_id = strip_id_uri(o)
            if not end_id in nodeid:
                nodeid[end_id] = str(len(nodeid))
            linkfile.write(",".join([nodeid[start_id], nodeid[end_id], strip_prop_uri(p)])+"\n")
        triple_count += 1

    vals.insert(0, start_id)
    vals.insert(0, nodeid[start_id])
    if args.neo4j:
        vals.append(labels)
    nodefile.write(",".join(vals)+"\n")

linkfile.close()
nodefile.close()

print("Number of triples = %d" % (triple_count))
