"""
Script to create a graph and output a GML file from the amazon dataset at http://snap.stanford.edu/data/amazon-meta.html.
Note: only certain product categories were kept and the category, or label, was taken from some catalog depth.
      The hierarchy of categories was not kept.
"""

import igraph
import collections

filein = open("amazon-meta.txt", "r")

def get_block(filein):
    block = ""
    line = filein.readline().strip()
    i = 0
    while line != "":
        block += line + "\n"
        line = filein.readline().strip()
    return block.split("\n")


get_block(filein)   # first block isn't relevant


nodeid = {}
categories = []
edges = []
index = 0
block = get_block(filein)
while block != [""]:
    asin = None
    neighbors = None
    category = None
    for line in block:
        line = line.strip()
        if line.startswith("group:"):
            group = line.split()[1].strip()
        elif line.startswith("ASIN:"):
            asin = line.split()[1].strip()
        elif line.startswith("similar:"):
            neighbors = line.split()[2:]
        elif line.startswith("|"):
            if group == "Book":
                if "Subjects[" in line:
                    ls = line.split("|")
                    if len(ls) > 3:
                        category = ls[3]
                        category = category.split("[")[0].strip()
                        break
            if group=="DVD" or group=="Video":
                if "Genres[" in line:
                    ls = line.split("|")
                    if len(ls) > 4:
                        category = ls[4]
                        category = category.split("[")[0].strip()
                        break
            if group == "Music":
                if "Styles[" in line:
                    ls = line.split("|")
                    if len(ls) > 3:
                        category = ls[3]
                        category = category.split("[")[0].strip()
                        break
    
    if category != None:
        nodeid[asin] = index
        edges += [(asin, v) for v in set(neighbors)]
        categories.append(group+": "+category)
        index += 1
    
    block = get_block(filein)

filein.close()

# Create graph in igraph and output as GraphML file
G = igraph.Graph()
G.add_vertices(index)
G.vs["label"] = categories

edges_by_id = []
for u,v in edges:
    if u in nodeid and v in nodeid:
        edges_by_id.append((nodeid[u],nodeid[v]))

G.add_edges(edges_by_id)

G.write_graphml("amazon-meta.graphml")
