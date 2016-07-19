#!/usr/bin/env python
################################################################################
# Copyright (C) 2016 Nginx, Inc.
#
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
# removed from the upstream group unless the minimum number of nodes has
# been reached.
################################################################################

import requests
import sys
import time
import datetime
import os
import math

# The following values can be changed to control the autoscaling behavior

STATUS_URL = 'http://localhost:8080/status' # The URL for the NGINX Plus status API
UPSTREAM_CONF_URL = 'http://localhost/upstream_conf' # The URL for the NGINX Plus configuration API.
SERVER_ZONE='nginx_ws' # The server zone to get the number of requests from
UPSTREAM_GROUP='nginx_backends' # The upstream group to scale
SLEEP_INTERVAL=2 # How long to wait between API requests, in seconds
MIN_NODES=2 # Minimum number of nodes to maintain in the upstream group
MAX_NODES=10 # Maximum number of nodes to allow in the upstream group
MAX_NODES_TO_ADD=4 # Maximum number of nodes to be added at one time
MAX_NODES_TO_REMOVE=2 # Maximum number of nodes to be remove at one time
# Make the following 2 variables floating point so values can be rounded up
MIN_RPS=10.0 # Scale down if the requests per second falls below this value
MAX_RPS=12.0 # Scale up if the requests per second exceeds this value

################################################################################
# Function getStatus
#
# Make a call to the NGINX Plus Status API.
################################################################################
def getStatus(client, path):

    url = STATUS_URL + path
    try:
        response = client.get(url) # Make an NGINX Plus status API call
    except requests.exceptions.ConnectionError:
        print "Error: Unable to connect to " + url
        sys.exit(1)

    if response.status_code == 200:
        return response.json()
    else:
        print("Error: status=%d") %(response.status_code)
        sys.exit(1)

################################################################################
# Function getRequestCount
#
# Use the Status API to the total request count from the server zone.
################################################################################
def getRequestCount(nginxStats):
	return nginxStats['server_zones'][SERVER_ZONE]['requests']

################################################################################
# Function addBackendNodes
#
# Add one or more backends to the upstream group.
################################################################################
def addBackendNodes(nodeCount):
    os.system('./addnginxws.sh ' + str(int(nodeCount)))

################################################################################
# Function removeBackendNodes
#
# Remove one or more backends to the upstream group.
################################################################################
def removeBackendNodes(nodeCount):
    os.system('./removenginxws.sh ' + str(int(nodeCount)))

################################################################################
# Function getNodeCounts
#
# Use the Status API to count the total number of nodes the upstream group
# and the number that are currently up.
################################################################################
def getNodeCounts(client, UPSTREAM_GROUP):

    path = '/upstreams/' + UPSTREAM_GROUP + '/peers'
    totalCount = 0
    upCount = 0

    nginxStats = getStatus(client, path)
    for stats in nginxStats:
        totalCount += 1
        if stats['state'] == 'up':
            upCount += 1

    nodeCounts = { 'totalNodes' : totalCount, 'upNodes' : upCount }
    return nodeCounts

################################################################################
# Main
################################################################################
def main():

    lastSeconds=0 # The timestamp for the previous API request
    currentSeconds=0 # The timestamp for the current API request
    lastRequests=0 # The number of requests processed as of the previous API request
    currentRequests=0 # The number of requests processed as of the current API request
    rps=0 # The requests per second since the previous API request
    nodeCount=0 # The current number of nodes in the upstream group

    client = requests.Session() # Create a session for making HTTP requests

    while True:
        now = datetime.datetime.now()
        currentSeconds= (now.hour * 60) + (now.minute * 60) + now.second
        nginxStats = getStatus(client, "")

        currentRequests = getRequestCount(nginxStats)

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
            nodeCounts = getNodeCounts(client, UPSTREAM_GROUP)
            totalNodes = nodeCounts['totalNodes']
            upNodes = nodeCounts['upNodes']
            # If upNodes is 0 then either there are no nodes, in which case
            # no traffic can be flowing and no scale up can be needed or there
            # was a problem getting the node information.
            if upNodes > 0:
                # Calculate the requests per second per backend node
                rpsPerNode = rps / upNodes
                neededNodes = math.ceil(rps / MAX_RPS)
                if rpsPerNode > MAX_RPS:
                    # Scale up unless the maximum nodes has been reached
                    if totalNodes < MAX_NODES:
                        # Make sure to add at least one node
                        newNodeCount = min(neededNodes - upNodes, MAX_NODES_TO_ADD, MAX_NODES - totalNodes)
                        print("Scale up %d nodes") %(newNodeCount)
                        addBackendNodes(newNodeCount)
                else:
                    if rpsPerNode < MIN_RPS:
                        # Scale down unless the minimum nodes has been reached
                        if upNodes > MIN_NODES:
                            newNodeCount = min(upNodes - neededNodes, MAX_NODES_TO_REMOVE, upNodes - MIN_NODES)
                            removeBackendNodes(newNodeCount)
        else:
            lastSeconds = currentSeconds
            lastRequests = currentRequests

        time.sleep(SLEEP_INTERVAL)

if __name__ == '__main__':
	main()
