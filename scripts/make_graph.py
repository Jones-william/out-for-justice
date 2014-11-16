
import pickle

from app.osm import read_osm
from app.optim import get_giant_component

def main(input_file, output_file):
    graph = read_osm(input_file)

    graph = get_giant_component(graph)

    print('Graph has {} nodes.'.format(graph.number_of_nodes()))
    print('Graph has {} edges.'.format(graph.number_of_edges()))

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
