import os
import sys
import json

import networkx as nx
from geojson import Point, GeometryCollection

from tornado.web import RequestHandler, StaticFileHandler
from tornado.httpserver import HTTPServer
from tornado.gen import coroutine

from osm import read_osm

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
    def initialize(self, graph):
        self.graph = graph

    def get(self):
        crime_type = self.get_query_argument('crime_type', 'theft')
        time_of_day = self.get_query_argument('tod', 'evening')
        day_of_week = self.get_query_argument('dow', 'weekend')

        geoms = []
        for node_id, node in self.graph.node.iteritems():
            geoms.append(Point([node['data'].lon, node['data'].lat]))
        geo = GeometryCollection(geoms)

        #geo = MultiPoint([(-155.52, 19.61), (-156.22, 20.74), (-157.97, 21.46)])
        return self.write_json(geo)

if __name__ == '__main__':
    from tornado.options import define, options
    from tornado.web import Application
    from tornado.ioloop import IOLoop

    define('conf', default='app/config.json', help='Configuration file')
    define('osm', default='data/sf.osm', help='Open Street Maps')

    options.parse_command_line()
    with open(options.conf) as f:
        config = json.load(f)


    with open(options.osm) as f:
        graph = read_osm(f)

    config['static_path'] = os.path.join(
        os.path.abspath(os.path.curdir),
        config['static_path']
    )
    app = Application([
        (r'/', MainHandler),
        (r'/api/heatmap.json', HeatMapHandler, {'graph': graph}),
        (r'/((?:css|fonts|js)/.*)', StaticFileHandler, {'path': config['static_path']}),
    ], **config)

    app.listen(config['port'])
    IOLoop.instance().start()
