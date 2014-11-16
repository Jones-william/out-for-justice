
import pickle

import random

import numpy as np

from sklearn.neighbors import NearestNeighbors

from app.optim import contract_edges

def main(input_file, output_file, perc=75):

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
    perc = np.percentile(distances[:,1], 50)
    to_merge = indices[d < perc]
    
    for i in range(to_merge.shape[0]):
        a, b = to_merge[i]
        a_id, b_id = id_map[a], id_map[b]

        if a_id not in graph or b_id not in graph:
            continue

        # pick the one with highest degree and randomly break ties
        new_node = sorted(
            [a_id, b_id], 
            key=lambda x: (-graph.degree(x), random.random())
        )[0]

        attr_dict = graph.node[new_node]
        
        contract_edges(graph, [a_id, b_id], new_node, attr_dict)

    print('New graph has {} nodes'.format(graph.number_of_nodes()))
    print('New graph has {} edges'.format(graph.number_of_edges()))

    with open(output_file, 'w') as f:
        pickle.dump(graph, f)

    return graph

if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument('input_file')
    parser.add_argument('output_file')

    args = parser.parse_args()
    main(args.input_file, args.output_file)
