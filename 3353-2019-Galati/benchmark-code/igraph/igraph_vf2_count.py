import sys
import time
import igraph
import random

def main():
    random.seed(13)         # the seed can affect affect the search path
    gfile = sys.argv[1]     # data graph file given as GraphML
    qfiles = sys.argv[2:]   # list of graphs (GraphML) to query in the data graph

    print("---- Graph: %s ----" % (gfile))
    
    st = time.time()
    G = igraph.load(gfile, format="graphml")
    load_time = time.time()-st

    print("---- times ----")
    print("load time: %.2f" % load_time)
    
    total_time = 0.0
    for qfile in qfiles:
        print("---- Query: %s ----" % (qfile))
        st = time.time()
        Q = igraph.load(qfile, format="graphml")
        loadQ_time = time.time()-st

        iso_time, num_matches= vf2(G, Q)

        query_time = loadQ_time+iso_time
        
        print("query time : %.2f" % query_time)
        print("num matches: %d" % (num_matches))
        
        total_time += query_time

    print("total query time: %.2f" % (total_time))
    print("total time: %.2f" % (total_time+load_time))
    print("\n")
    

def vf2(G, Q):
    # Delete the 'id' attribute that sometimes is auto-created by igraph
    if "id" in G.vs[0].attributes():
        del G.vs["id"]
    if (G.ecount() > 0 and "id" in G.es[0].attributes()):
        del G.es["id"]
    if "id" in Q.vs[0].attributes():
        del Q.vs["id"]
    if (Q.ecount() > 0 and "id" in Q.es[0].attributes()):
        del Q.es["id"]

    # Note, this only works with at most a single attribute on vertices and edges.
    # Also, does not match 'wildcard'. A blank attribute will be matched with other blank attributes.
    if len(Q.vs[0].attributes()) <= 1 and (Q.ecount() == 0 or len(Q.es[0].attributes()) <= 1):
        # If vertex attributes, convert to 'color' dictionary objects
        # Must convert attribute to integer, else we get 'TypeError: sequence elements must be integers'
        G_colors = None
        Q_colors = None
        if len(Q.vs[0].attributes()) > 0:
            attr = list(Q.vs[0].attributes())[0]
            color = {label:i for i,label in enumerate(set(G.vs[attr]))}
            G_colors = [color[l] for l in G.vs[attr]]
            Q_colors = [color[l] for l in Q.vs[attr]]
        
        # If edge attributes, convert to 'color' dictionary objects
        G_ecolors = None
        Q_ecolors = None
        if Q.ecount() > 0 and len(Q.es[0].attributes()) > 0:
            attr = list(Q.es[0].attributes())[0]
            color = {label:i for i,label in enumerate(set(G.es[attr]))}
            G_ecolors = [color[l] for l in G.es[attr]]
            Q_ecolors = [color[l] for l in Q.es[attr]]

        # Run iso algorithm 
        st = time.time()
        nmatches = G.count_subisomorphisms_vf2(Q, color1=G_colors, color2=Q_colors, edge_color1=G_ecolors, edge_color2=Q_ecolors)
        iso_time = time.time() - st
    
        return iso_time, nmatches
    else:
        print("Too many attributes, did not run")
        exit(1)


if __name__ == "__main__":
    main()
