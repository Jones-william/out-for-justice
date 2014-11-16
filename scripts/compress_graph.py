
import networkx as nx
import pickle

import random

import numpy as np

from sklearn.neighbors import NearestNeighbors

def contract_edges(G,nodes, new_node, attr_dict=None, **attr):
    """Contracts the edges of the nodes in the set "nodes"
    From: https://gist.github.com/aanastasiou/7639465
    """
    #Add the node with its attributes
    G.add_node(new_node, attr_dict, **attr)
    #Create the set of the edges that are to be contracted
    cntr_edge_set = G.edges(nodes, data = True)
    #Add edges from new_node to all target nodes in the set of edges that are to be contracted
    #Possibly also checking that edge attributes are preserved and not overwritten, 
    #especially in the case of an undirected G (Most lazy approach here would be to return a 
    #multigraph so that multiple edges and their data are preserved)
    G.add_edges_from(map(lambda x: (new_node,x[1],x[2]), cntr_edge_set)) 
    #Remove the edges contained in the set of edges that are to be contracted, concluding the contraction operation
    G.remove_edges_from(cntr_edge_set)
    #Remove the nodes as well
    G.remove_nodes_from(nodes)
    #Return the graph
    return G

def merge_node(graph, winner, loser):
    # loser disappears from graph
    # winner gets all his edges

    for u, v in graph.edges(loser):
        assert u == loser
        graph.add_edge(winner, v)
    
    graph.remove_node(loser)
    

def main(input_file, output_file, percent=75):

    with open(input_file) as f:
        graph = pickle.load(f)

    node_map = {}
    id_map = {}
    coords = []
    for node_id in graph.nodes_iter():
        new_id = len(node_map)
        node_map[node_id] = new_id
        id_map[new_id] = node_id

        data = graph.node[node_id]['data']
        coords.append([data.lat, data.lon ])

    X = np.array(coords)
    n = NearestNeighbors(n_neighbors=2)
    n.fit(X)
    distances, indices = n.kneighbors(X)

    # figure out the close nodes and merge them
    d = distances[:,1]
    perc = np.percentile(distances[:,1], percent)
    to_merge = indices[d < perc]
    
    for i in range(to_merge.shape[0]):
        a, b = to_merge[i]
        a_id, b_id = id_map[a], id_map[b]

        if a_id not in graph or b_id not in graph:
            continue

        # pick the one with highest degree and randomly break ties
        node_order = sorted(
            [a_id, b_id], 
            key=lambda x: (-graph.degree(x), random.random())
        )

        merge_node(graph, *node_order)
        #attr_dict = graph.node[new_node]
        
        #contract_edges(graph, [a_id, b_id], new_node, attr_dict)

    print('New graph has {} nodes'.format(graph.number_of_nodes()))
    print('New graph has {} edges'.format(graph.number_of_edges()))
    print('New graph as {} connected components'.format(
        len(nx.connected_components(graph))))

    with open(output_file, 'w') as f:
        pickle.dump(graph, f)

    return graph

if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument('input_file')
    parser.add_argument('output_file')
    parser.add_argument('--percent', type=int, default=75)

    args = parser.parse_args()
    main(args.input_file, args.output_file, args.percent)
