
import pickle
import pandas as pd
from geojson import Point, GeometryCollection, dump


def main(input_file):
    with open(input_file) as f:
        graph = pickle.load(f)

    node_map = {int(node_id): i for i, node_id in enumerate(graph.nodes())}

    outcomes = []
    for fn, name in [
        ('data/sfnodesdtINTOXICATIONCRIME.csv', 'intoxication'),
        ('data/sfnodesdtPROPERTYCRIME.csv', 'property'),
        ('data/sfnodesdtVIOLENTCRIME.csv', 'violent'),
    ]:
        df = pd.read_csv(fn)
        df['crime_type'] = name
        outcomes.append(df)

    df = pd.concat(outcomes)
    df['id'] = df['id'].apply(node_map.get)

    df = df[df['id'].notnull()]

    for (tod, dow), time_df in df.groupby(['daytime', 'superday']):

        points = []
        for node_id, node_df in time_df.groupby('id'):

            # so so sorry future sean
            values = node_df[['id', 'crime_type', 'preds']].set_index('crime_type').to_dict()['preds']

            points.append(
                Point(
                    [df['X'].values[0], df['Y'].values[0]],
                    node_id=node_id,
                    **values
                ))

        geo = GeometryCollection(points)
        outfile = 'www/json/sf_crime_{}_{}.json'.format(
            tod.lower().replace('-','_'),
            dow.lower()
        )
        with open(outfile, 'w') as f:
            dump(geo, f)


if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument('input_file')

    args = parser.parse_args()
    main(args.input_file)
