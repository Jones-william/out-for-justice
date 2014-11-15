.PHONY: data deps

deps:
	pip install -r requirements.txt

data: data/calls.csv data/incidents.csv data/sfpd_service_calls.csv

data/calls.csv:
	wget https://s3-us-west-1.amazonaws.com/acs-sfpd-data/calls.csv

data/incidents.csv:
	wget https://s3-us-west-1.amazonaws.com/acs-sfpd-data/incidents.csv

data/sfpd_service_calls.csv:
	wget https://s3-us-west-1.amazonaws.com/acs-sfpd-data/sfpd_service_calls.csv

