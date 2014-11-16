from __future__ import print_function

import os
import sys
import json
import pickle
import random

import numpy as np
import networkx as nx

from tornado.web import RequestHandler, StaticFileHandler
from tornado.httpserver import HTTPServer
from tornado.gen import coroutine

# so so lazy
sys.path.append('.')
from app.optim import slow_compute_loss, random_downhill_walk

timestr = {
    'morning': '2am_10am',
    'daytime': '10am_6pm',
    'evening': '6pm_2am',
}

class BaseHandler(RequestHandler):
    def initialize(self, db=None):
        self.db = db

    def get_current_user(self):
        user_id = self.get_secure_cookie('userid')
        #if not user_id:
        #    token = self.get_argument('access_token', None)
        return user_id

    def get_static_url(self, path):
        return '%s://%s%s' % (self.request.protocol, self.request.host, path)

    def write_json(self, d):
        self.write(json.dumps(d))


class MainHandler(BaseHandler):
    def get(self):
        return self.render('index.html')


class HeatMapHandler(BaseHandler):

    def get(self):
        time_of_day = timestr[self.get_query_argument('tod', 'evening')]
        day_of_week = self.get_query_argument('dow', 'friday')

        fn = 'json/sf_crime_{}_{}.json'.format(time_of_day, day_of_week)

        return self.render(fn)


class LossHandler(BaseHandler):
    """
    Compute loss from car positioning.
    """
    def initialize(self, graph):
        self.graph = graph

    def compute_loss(self, risks, positions):
        N = self.graph.number_of_nodes()
        positions_vec = np.zeros(N)
        positions_vec[positions] = 1

        loss = slow_compute_loss(self.graph, positions_vec, risks, agg=None)
        loss = dict(zip(['intoxication', 'property', 'violent'], loss.mean(0)))
        loss['positions'] = positions
        return self.write_json(loss)

    def post(self):
        params = json.loads(self.request.body)

        time_of_day = timestr[params.get('tod', 'evening')]
        day_of_week = params.get('dow', 'friday')

        if 'positions' in params:
            positions = params['positions'] # list of integers
        elif 'num_cars' in params:
            positions = random.sample(
                xrange(self.graph.number_of_nodes()),
                params['num_cars'])                      
        else:
            assert 0

        fn = 'data/sf_crime_risks_{}_{}.npy'.format(time_of_day, day_of_week)
        risks = np.load(fn)

        return self.compute_loss(risks, positions)

class StepHandler(LossHandler):
    def post(self):
        params = json.loads(self.request.body)

        time_of_day = timestr[params.get('tod', 'evening')]
        day_of_week = params.get('dow', 'friday')
        positions = params['positions'] # list of integers
        steps = params.get('steps', 5)
        prob_step = params.get('prob_step', .25)

        fn = 'data/sf_crime_risks_{}_{}.npy'.format(time_of_day, day_of_week)
        risks = np.load(fn)

        N = self.graph.number_of_nodes()
        positions_vec = np.zeros(N)
        positions_vec[positions] = 1

        new_positions = random_downhill_walk(self.graph, positions_vec, risks,
                                             num_steps=steps,
                                             prob_step=prob_step)

        return self.compute_loss(risks, list(new_positions.nonzero()[0]))

if __name__ == '__main__':
    from tornado.options import define, options
    from tornado.web import Application
    from tornado.ioloop import IOLoop

    define('conf', default='app/config.json', help='Configuration file')
    define('graph', default='data/sf_compressed_graph.pkl', help='Graph')

    options.parse_command_line()

    with open(options.conf) as f:
        config = json.load(f)

    with open(options.graph) as f:
        print('Loading graph...', end=' ')
        graph = pickle.load(f)
        graph = nx.convert_node_labels_to_integers(graph)
        print('Done.')

    config['static_path'] = os.path.join(
        os.path.abspath(os.path.curdir),
        config['static_path']
    )
    app = Application([
        (r'/', MainHandler),
        (r'/api/heatmap.json', HeatMapHandler),
        (r'/api/loss', LossHandler, {'graph': graph}),
        (r'/api/step', StepHandler, {'graph': graph}),
        (r'/((?:css|fonts|js|img|json)/.*)', StaticFileHandler, {'path': config['static_path']}),
    ], **config)

    app.listen(config['port'])
    IOLoop.instance().start()
