#!/usr/bin/env python

import requests
import sys
import os

# Get all variables from environment

params = dict()

requireds = ['WISDOM_FILE', 
             'COMMENTS_URL', 
             'AUTH_HEADER', 
             'HEADER', 
             'API_VERSION',
             'GITHUB_TOKEN']

for required in requireds:
    
    value = os.environ.get(required)
    if required == None:
        print('Missing environment variable %s' %required)
        sys.exit(1)

    params[required] = value


infile = params['WISDOM_FILE']

if not os.path.exists(infile):
    print('Does not exist: %s' %infile)
    sys.exit(1)
    

with open(infile, 'r') as filey:
    wisdom = filey.read()

# Prepare request
accept = "application/vnd.github.%s+json;application/vnd.github.antiope-preview+json" % params['API_VERSION']
headers = {"Authorization": "token %s" % params['GITHUB_TOKEN'],
           "Accept": accept,
           "Content-Type": "application/json" }

wisdom = "GitHub Confucious Action Say: \n" + wisdom 
data = {"body": wisdom }
print(data)
response = requests.post(params['COMMENTS_URL'],
                         data = data, 
                         headers = headers)
print(response.json())
print(response.status_code)
print(response.text)
