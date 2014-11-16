
import random
import pickle

import numpy as np
import networkx as nx

from app.optim import slow_compute_loss, step

def main(input_file, num_police, num_steps, prob_step):
    """
    Parameters
    ----------
    num_police : the number of police to use
    num_steps : the number of steps to take
    prob_step : the probability of taking a step if it doesn't improve loss
    """
    with open(input_file) as f:
        graph = pickle.load(f)


    graph = nx.convert_node_labels_to_integers(graph)

    N = graph.number_of_nodes()

    # compute random starting places
    starting_positions = np.zeros(N)
    places = random.sample(xrange(N), num_police)
    starting_positions[places] = 1

    # one outcome that is uniformly distributed
    risks = np.ones(N).reshape((-1, 1))

    import time
    start = time.time()

    # initialize the optimization
    positions = [starting_positions]
    losses = [slow_compute_loss(graph, positions[-1], risks)]
    current = positions[-1]

    tried = set()
    for i in range(num_steps):

        new_position = step(graph, current)
        pos_id = tuple(new_position.nonzero()[0])
        if pos_id in tried:
            continue

        tried.add(pos_id)

        positions.append(new_position)
        losses.append(slow_compute_loss(graph, new_position, risks))

        if (losses[-1] < losses[-2]) or (random.random() < prob_step):
            current = new_position

    print time.time() - start


    print sorted(losses)[:10]

if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument('input_file')
    parser.add_argument('--num_police', type=int, default=1)
    parser.add_argument('--num_steps', type=int, default=100)
    parser.add_argument('--prob_step', type=float, default=0.25)

    args = parser.parse_args()
    main(args.input_file, args.num_police, args.num_steps, args.prob_step)
