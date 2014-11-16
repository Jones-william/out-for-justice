
import random
import numpy as np
import networkx as nx

def get_giant_component(g):
    """
    Take only the big connected component of the graph.
    """
    graphs = nx.connected_component_subgraphs(g)
    graphs.sort(key=lambda x: -x.number_of_nodes())
    return graphs[0]

def step(graph, positions):
    """
    Parameters
    ----------
    graph : networkx graph of points on the map
    positions : the current positions which are occupied by a police car
         N-array
    id_map : dictionary which maps positions into node_ids
    """
    old = random.choice(positions.nonzero()[0])

    new = random.choice(graph.neighbors(old))

    new_positions = positions.copy()
    new_positions[old] = 0
    new_positions[new] = 1

    return new_positions

#def random_step(graph):
#    old = random.choice(positions.nonzero()[0])


def compute_loss(dist_mat, positions, risks, agg=np.sum):
    """
    Parameters
    ----------
    dist_matrix : pre-computed array of distances between all points.
        N x N array
    positions : the current positions which are occupied by a police car.
        N-array of current positions of cars
    risks : the risks of crime for each position
        N x K array (N is number of points, K is number of crimes types)
    """
    assert dist_mat.shape[0] == dist_mat.shape[1]
    assert positions.shape[0] == dist_mat.shape[0]
    assert risks.shape[0] == dist_mat.shape[0]

    available_dists = dist_mat[:,positions.astype(np.bool)]
    best_dist = available_dists.min(1).reshape((-1, 1))
    
    by_place = (best_dist * risks)
    if agg is not None:
        return agg(by_place)
    else:
        return by_place


def slow_compute_loss(graph, positions, risks, agg=np.sum):
    """
    Slow compute loss assumes we don't have a distance matrix available
    (which is true until we figure out how to store 60k^2 matrices)

    Parameters
    ----------
    graph : networkx graph
    positions : the current positions which are occupied by a police car.
        N-array of current positions of cars
    risks : the risks of crime for each position
        N x K array (N is number of points, K is number of crimes types)
    """
    
    vecs = []
    for index in positions.nonzero()[0]:
        distances = nx.shortest_path_length(graph, source=index)
        assert len(distances) == len(positions)
        vecs.append([distances[i] for i in range(positions.shape[0])])
        

    dist_mat = np.array(vecs).T

    assert positions.shape[0] == dist_mat.shape[0]
    assert risks.shape[0] == dist_mat.shape[0]

    best_dist = dist_mat.min(1).reshape((-1, 1))
    
    by_place = (best_dist * risks)

    if agg is not None:
        return agg(by_place)
    else:
        return by_place

def random_downhill_walk(graph, positions, risks, num_steps=100, 
                         prob_step=.25,
                         random_jump=0.50):
    """
    Parameters
    ----------
    graph : networkx graph to walk over
    positions : starting positions
    risks : risks of activities
    """

    # initialize the optimization
    positions = [positions]
    losses = [slow_compute_loss(graph, positions[-1], risks)]
    current = positions[-1]
    tried = set() # don't evalute the (costly) loss function twice

    for i in range(num_steps):

        new_position = step(graph, current)
        pos_id = tuple(new_position.nonzero()[0])
        if pos_id in tried:
            continue

        tried.add(pos_id)

        positions.append(new_position)
        losses.append(slow_compute_loss(graph, new_position, risks, agg=np.sum))

        if (losses[-1] < losses[-2]) or (random.random() < prob_step):
            current = new_position

    return sorted(enumerate(positions), key=lambda x: losses[x[0]])[0][1]
    
def test_compute_loss():
    dm = np.array([
        [0, 1, 2],
        [1, 0, 1],
        [2, 1, 0],
    ])

    g = make_test_graph()

    risks = np.array([
        [0.2, 0.3, 0.1, 0.5],
        [0.1, 0.1, 0.05, 0.04],
        [0.0, 0.01, 0.03, 0.02],
        ])

    positions = np.array([0, 0, 1])
    a = compute_loss(dm, positions, risks)
    a_ = slow_compute_loss(g, positions, risks)
    assert a == a_
    positions = np.array([0, 1, 0])
    b = compute_loss(dm, positions, risks)
    b_ = slow_compute_loss(g, positions, risks)
    assert b == b_
    positions = np.array([1, 0, 0])
    c = compute_loss(dm, positions, risks)
    c_ = slow_compute_loss(g, positions, risks)
    assert c == c_

    assert a > b > c

    # same thing with max-loss 
    positions = np.array([0, 0, 1])
    a = compute_loss(dm, positions, risks, np.max)
    positions = np.array([0, 1, 0])
    b = compute_loss(dm, positions, risks, np.max)
    positions = np.array([1, 0, 0])
    c = compute_loss(dm, positions, risks, np.max)
    
    assert a > b > c

def make_test_graph():
    g = nx.Graph()
    [g.add_node(i) for i in range(3)]
    g.add_edge(0,1)
    g.add_edge(1,2)
    return g

def test_step():
    g = make_test_graph()

    assert step(g, np.array([1,0,0]))[1] == 1
    assert step(g, np.array([0,0,1]))[1] == 1

    positions = [np.array([0,0,1])]
    for i in range(10000):
        positions.append(step(g, positions[-1]))

    means = np.array(positions).mean(0)
    assert abs(means[1]  - .5) < .01

if __name__ == '__main__':
    test_compute_loss()
    test_step()
