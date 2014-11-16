
import numpy as np
import networkx as nx

def distance_matrix(g):
    """
    Compute a pairwise distance matrix for a graph.  This takes some time.
    """
    X = nx.all_pairs_shortest_path_length(graph)


def get_giant_component(g):
    """
    Take only the big connected component of the graph.
    """
    graphs = nx.connected_component_subgraphs(g)
    graphs.sort(key=lambda x: -x.number_of_nodes())
    return graphs[0]

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


def compute_loss(dist_mat, positions, rates, weights, agg=np.sum):
    """
    Parameters
    ----------
    dist_matrix : pre-computed array of distances between all points.
        N x N array
    positions : the current positions which are occupied by a police car.
        N-array of current positions of cars
    rates : the rates of crime for each position
        N x K array (N is number of points, K is number of crimes types)
    weights : the weights applied to each crime
        K-array
    """
    assert dist_mat.shape[0] == dist_mat.shape[1]
    assert positions.shape[0] == dist_mat.shape[0]
    assert rates.shape[0] == dist_mat.shape[0]
    assert weights.shape[0] == rates.shape[1]

    available_dists = dist_mat[:,positions.astype(np.bool)]
    best_dist = available_dists.min(1).reshape((-1, 1))
    
    by_place = (best_dist * rates * weights).sum(1)
    return agg(by_place)
    
def test_compute_loss():
    dm = np.array([
        [0, 1, 2],
        [1, 0, 1],
        [2, 1, 0],
    ])
    

    rates = np.array([
        [0.2, 0.3, 0.1, 0.5],
        [0.1, 0.1, 0.05, 0.04],
        [0.0, 0.01, 0.03, 0.02],
        ])

    weights = np.array([1, 5, 10, 20])

    positions = np.array([0, 0, 1])
    a = compute_loss(dm, positions, rates, weights)
    positions = np.array([0, 1, 0])
    b = compute_loss(dm, positions, rates, weights)
    positions = np.array([1, 0, 0])
    c = compute_loss(dm, positions, rates, weights)

    assert a > b > c

    positions = np.array([0, 0, 1])
    a = compute_loss(dm, positions, rates, weights, np.max)
    positions = np.array([0, 1, 0])
    b = compute_loss(dm, positions, rates, weights, np.max)
    positions = np.array([1, 0, 0])
    c = compute_loss(dm, positions, rates, weights, np.max)
    
    assert a > b > c


if __name__ == '__main__':
    test_compute_loss()
