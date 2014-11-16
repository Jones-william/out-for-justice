
from csv import DictWriter
import pickle

from app.osm import read_osm
from app.optim import get_giant_component

def main(input_file, output_file):
    with open(input_file) as f:
        graph = pickle.load(f)

    print('Graph has {} nodes.'.format(graph.number_of_nodes()))

    with open(output_file, 'w') as f:
        writer = DictWriter(f, ['id', 'lat', 'lon'])
        writer.writeheader()
        
        for node_id in graph.nodes_iter():
            data = graph.node[node_id]['data']

            writer.writerow({
                'id': node_id,
                'lat': data.lat,
                'lon': data.lon,
            })

    return graph

if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument('input_file')
    parser.add_argument('output_file')

    args = parser.parse_args()
    main(args.input_file, args.output_file)
