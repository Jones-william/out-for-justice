.PHONY: data deps

deps:
	pip install -r requirements.txt
	git clone https://gist.github.com/aflaxman/287370 lib/osm

data/sf_points.csv: data/sf_graph.pkl
	PYTHONPATH=. python scripts/make_points.py $< $@

data/sf_compressed_graph.pkl: data/sf_graph.pkl
	PYTHONPATH=. python scripts/compress_graph.py $< $@

data/sf_graph.pkl: data/sf.osm
	PYTHONPATH=. python scripts/make_graph.py $< $@

data: data/calls.csv data/incidents.csv data/sfpd_service_calls.csv data/sf.osm

data/sf_sample.osm:
	wget -O $@ "http://overpass.osm.rambler.ru/cgi/xapi_meta/ways?*[bbox=-122.417008,37.74661,-122.407779,37.754089][highway=*]"

data/sf.osm:
	wget -O $@ "http://overpass.osm.rambler.ru/cgi/xapi_meta/ways?*[bbox=-122.515198,37.727604,-122.381687,37.809443][highway=*]"

data/calls.csv:
	wget -O $@ https://s3-us-west-1.amazonaws.com/acs-sfpd-data/calls.csv

data/incidents.csv:
	wget -O $@ https://s3-us-west-1.amazonaws.com/acs-sfpd-data/incidents.csv

data/sfpd_service_calls.csv:
	wget -O $@ https://s3-us-west-1.amazonaws.com/acs-sfpd-data/sfpd_service_calls.csv

