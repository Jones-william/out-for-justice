.PHONY: data deps

deps:
	pip install -r requirements.txt
	git clone https://gist.github.com/aflaxman/287370 lib/osm

data: data/calls.csv data/incidents.csv data/sfpd_service_calls.csv data/sf.osm

data/sf_sample.osm:
	wget -O $@ "http://overpass.osm.rambler.ru/cgi/xapi_meta/ways?*[bbox=-122.417008,37.74661,-122.407779,37.754089][highway=*]"

data/sf.osm:
	wget -O $@ "http://overpass.osm.rambler.ru/cgi/xapi_meta/ways?*[bbox=-122.440354,37.736021,-122.381687,37.768203][highway=*]"

data/calls.csv:
	wget -O $@ https://s3-us-west-1.amazonaws.com/acs-sfpd-data/calls.csv

data/incidents.csv:
	wget -O $@ https://s3-us-west-1.amazonaws.com/acs-sfpd-data/incidents.csv

data/sfpd_service_calls.csv:
	wget -O $@ https://s3-us-west-1.amazonaws.com/acs-sfpd-data/sfpd_service_calls.csv

