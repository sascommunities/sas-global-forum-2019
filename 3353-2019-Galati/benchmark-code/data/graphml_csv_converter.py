"""
Converts a GraphML file to CSV.
Can convert into format for batch insert into Neo4j.
"""

import sys
import igraph
import argparse

parser = argparse.ArgumentParser(description="Generates synthetic graph")
parser.add_argument("gpath", help="Path to GraphML file to convert")
parser.add_argument("--neo4j",  help="Neo4j output style (separate header files)", action="store_true")
args = parser.parse_args()

G = igraph.load(args.gpath, format="graphml")
    
# Node properties
vprops = []
if len(G.vs[0].attributes()) > 0:
    vprops = list(G.vs[0].attributes().keys())
    if "id" in vprops:
        vprops.remove("id")

# Link properties
eprops = []
if len(G.es[0].attributes()) > 0:
    eprops = list(G.es[0].attributes().keys())
    if "id" in eprops:
        eprops.remove("id")


# Create csv file for nodes
with open("nodes.csv", "w") as fout:
    if not args.neo4j:
        fout.write("node")
        for p in vprops:
            fout.write(","+p)
        fout.write("\n")
    
    for v in G.vs:
        vals = [v["id"]]
        vals += ['"'+str(v[p])+'"' for p in vprops]
        fout.write(",".join(vals)+"\n")


# Create csv file for links
with open("links.csv", "w") as fout:
    if not args.neo4j:
        fout.write("from,to")
        for p in eprops:
            fout.write(","+p)
        fout.write("\n")
    
    for e in G.es:
        vals = [G.vs[idx]["id"] for idx in e.tuple]
        if args.neo4j:
            vals.append("rel") # Neo4j requires type on each relationship
        vals += ['"'+str(e[p])+'"' for p in eprops]
        fout.write(",".join(vals)+"\n")


# Create header files for Neo4j
if args.neo4j:
    with open("nodes_header.csv", "w") as fout:
        fout.write(":ID")
        for p in vprops:
            fout.write(","+p)
        fout.write("\n")
    
    with open("links_header.csv", "w") as fout:
        fout.write(":START_ID,:END_ID,:TYPE")
        for p in eprops:
            fout.write(","+p)
        fout.write("\n")
