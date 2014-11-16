
import pickle

import numpy as np
import pandas as pd

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
        mat = time_df.set_index(['id', 'crime_type'])['preds'].unstack()

        outfile = 'data/sf_crime_risks_{}_{}.npy'.format(
            tod.lower().replace('-','_'),
            dow.lower()
        )

        np.save(outfile, mat.values)

if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument('input_file')

    args = parser.parse_args()
    main(args.input_file)
