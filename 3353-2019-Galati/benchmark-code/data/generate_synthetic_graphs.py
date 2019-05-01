import random
import igraph
import argparse

try:
    random.seed(0, version=1)   # Python 3
except TypeError:
    random.seed(0)              # Python 2

def randint(lo, hi):
    return int(lo+hi*random.random())

parser = argparse.ArgumentParser(description="Generates synthetic graph")
parser.add_argument("model",    help="Graph model to use", choices=["barabasi", "erdos"])
parser.add_argument("nodes",    help="Approximate number of nodes",     type=int)
parser.add_argument("edges",    help="Approximate number of edges",     type=int)
parser.add_argument("vlabels",  help="Number of unique vertex labels",  type=int)
parser.add_argument("elabels",  help="Number of unique edges labels",   type=int)
parser.add_argument("outfile",  help="Output filename")
args = parser.parse_args()

num_nodes   = args.nodes
num_edges   = args.edges
num_vlabels = args.vlabels
num_elabels = args.elabels
nei         = int(num_edges/num_nodes)

# Generate random graph
if args.model == 'barabasi':
    graph = igraph.Graph.Barabasi(num_nodes, nei, directed=False)
if args.model == 'erdos':
    graph = igraph.Graph.Erdos_Renyi(num_nodes, m=num_edges, directed=False)

# Generate random vertex and edge labels
if num_vlabels > 0:
    graph.vs["label"] = [str(randint(1, num_vlabels)) for i in range(graph.vcount())]
if num_elabels > 0:
    graph.es["label"] = [str(randint(1, num_elabels)) for i in range(graph.vcount())]

# Output graph
graph.write_graphml(args.outfile)

print("number of vertices: %d" % (graph.vcount()))
print("   number of edges: %d" % (graph.ecount()))
