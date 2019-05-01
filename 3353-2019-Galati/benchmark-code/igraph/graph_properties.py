import sys
import igraph

def stats(graph):
    avg_degree = sum(graph.degree(igraph.VertexSeq(graph)))/float(graph.vcount())
    
    print("vertices     : %.2f" % (graph.vcount()))
    print("edges        : %.2f" % (graph.ecount()))
    print("diameter     : %.2f" % (graph.diameter()))
    print("avg degree   : %.2f" % (avg_degree))

gfile = sys.argv[1]
G = igraph.load(gfile, format="graphml")
stats(G)
