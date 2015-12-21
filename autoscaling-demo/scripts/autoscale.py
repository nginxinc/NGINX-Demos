#!/usr/bin/env python  
################################################################################
# Copyright (C) 2015 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# A proof of concept for auto-scaling an NGINX Plus upstream group
#
# This script periodically makes a request to the NGINX Plus status API 
# and computes the request rate based on the number of requests that have
# been processed since the last API call and the number of nodes, both up
# and total in the upstream group.  If the request rate per up node is above
# the specified maximum request rate, one or more nodes will be added to
# the upstream group using the NGINX Plus upstream_conf API, unless the 
# maximum number of total nodes has been reached.  If the request rate 
# per up node is below the specified limit, one or more nodes will be 
# removed from the# upstream group unless the minimum number of nodes 
# has been reached.
################################################################################

import requests  
import json  
import sys  
import time
import datetime
import os
import math

# The following values can be changed to control the autoscaling behavior
  
statusURL = 'http://localhost:8080/status' # The URL for the NGINX Plus status API
confURL = 'http://localhost/upstream_conf' # The URL for the NGINX Plus configuration API.
serverBlock='nginx_ws' # The server block to get the number of requests from 
upstream='nginx_backends' # The upstream group to scale
sleepInterval=2 # How long to wait between API requests
minNodes=2 # Minimum number of nodes to mainint in the upstream group
maxNodes=10 # Maximum number of node to allow in the upstream group
maxNodesToAdd=4 # Maximum number of nodes to be added at one time
maxNodesToRemove=2 # Maximum number of nodes to be remove at one time
# Make the following 2 variables floating point so values can be rounded up
minRPS=10.0 # Scale down if the requests per second falls below this value
maxRPS=12.0 # Scale up if the requests per second exceeds this value

# These values shoudl not be changed
lastSeconds=0 # The timestamp for the previous API request
currentSeconds=0 # The timestamp for the current API request
lastRequests=0 # The number of requests processed as of the previous API request
currentRequests=0 # The number of requests processed as of the current API request
rps=0 # The requests per second since the previous API request
nodeCount=0 # The current number of nodes in the upstream group

client = requests.Session() # Create a session for making HTTP requests 

################################################################################
# Function getNodeCounts
# 
# Use the Status API to count the total number of nodes the upstream group
# and the number that are currently up
################################################################################

def getNodeCounts(client, statusURL, upstream):
    url = statusURL + '/upstreams/' + upstream + '/peers'
    totalCount = 0
    upCount = 0
    try:
        response = client.get(url) # Make an NGINX Plus status API call
    except requests.exceptions.ConnectionError:
        print "Error: Unable to connect to " + statusURL
        sys.exit(1)
    if response.status_code == 200:
        nginxstats = json.loads(response.content) # Convert JSON to dict
        for stats in nginxstats:
            totalCount += 1
            if stats['state'] == 'up':
                upCount += 1
    else:
        print("Error: status=%d") %(response.status_code)
        sys.exit(1)

    nodeCounts = { 'totalNodes' : totalCount, 'upNodes' : upCount }
    return nodeCounts

################################################################################
# Main
################################################################################

i = 1
while i == 1: # Loop forever
    now = datetime.datetime.now()
    currentSeconds= (now.hour * 60) + (now.minute * 60) + now.second
    try:  
        response = client.get(statusURL) # Make an NGINX Plus status API call 
    except requests.exceptions.ConnectionError:  
        print "Error: Unable to connect to " + statusURL
        sys.exit(1)  
    if response.status_code == 200:  
        nginxstats = json.loads(response.content) # Convert JSON to dict 
        # Get the current request count
        currentRequests=nginxstats['server_zones'][serverBlock]['requests']

        if lastSeconds > 0:
            # calculate how many seconds have elapsed since the last API request
            interval = currentSeconds - lastSeconds
            # Calculate the total requests per second since the last API request
            rps = (currentRequests - lastRequests) / interval
            lastSeconds = currentSeconds
            lastRequests = currentRequests
            # Get the total number nodes in the upstream group, and the total that
            # that are currently up.  Do the RPS calculation on the up nodes, but
            # still respect the total allowed nodes.
            nodeCounts = getNodeCounts(client, statusURL, upstream)
            totalNodes = nodeCounts['totalNodes']
            upNodes = nodeCounts['upNodes']
            # If upNodes is 0 then either there are no nodes, in which case
            # no traffic can be flowing and no scale up can be needed or there
            # was a problem getting the node information. 
            if upNodes > 0:
                # Calculate the requests per second per backend node
                rpsPerNode = rps / upNodes
                neededNodes = math.ceil(rps / maxRPS)
                if rpsPerNode > maxRPS:
                    # Scale up unless the maximum nodes has been reached
                    if totalNodes < maxNodes:
                        # Make sure to add at least one node
                        nodesToScale = min(neededNodes - upNodes, maxNodesToAdd, maxNodes - totalNodes)
                        print("Scale up %d nodes") %(nodesToScale)
                        os.system('./addnginxws.sh ' + str(int(nodesToScale)))
                else:
                    if rpsPerNode < minRPS:
                        # Scale down unless the minimum nodes has been reached
                        if upNodes > minNodes:
                            nodesToScale = min(upNodes - neededNodes, maxNodesToRemove, upNodes - minNodes)
                            os.system('./removenginxws.sh ' + str(int(nodesToScale)))
        else:        
            lastSeconds = currentSeconds
            lastRequests = currentRequests
    else:
        print("Error: status=%d") %(response.status_code)
    time.sleep(sleepInterval)
