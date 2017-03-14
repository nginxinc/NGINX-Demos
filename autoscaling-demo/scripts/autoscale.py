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
#
# The settings that control the autoscaling behavior can be set on the
# command line or the default values can be used.  -h or --help will print
# out the complete list of command line parameters.
################################################################################

import requests
import sys
import time
import datetime
import os
import argparse
import math

# The following values can be changed to control the autoscaling behavior

NGINX_STATUS_URL = 'http://localhost:8080/status' # The URL for the NGINX Plus status API
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
def getStatus(client, statusURL, path):

    url = statusURL + path
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
def getNodeCounts(client, statusURL, upstreamGroup):

    path = '/upstreams/' + upstreamGroup + '/peers'
    totalCount = 0
    upCount = 0

    nginxStats = getStatus(client, statusURL, path)
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

    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Provide more detailed output")
    parser.add_argument("--nginx_status_url", default=NGINX_STATUS_URL,
                        help="URL for NGINX Plus Status API")
    parser.add_argument("--nginx_server_zone", default=SERVER_ZONE,
                        help="The NGINX Plus server zone to collect requests count from")
    parser.add_argument("--nginx_upstream_group", default=UPSTREAM_GROUP,
                        help="The NGINX Plus upstream group to scale")
    parser.add_argument("--sleep_interval", type=int, default=SLEEP_INTERVAL,
                        help="The sleep interval between checking the status")
    parser.add_argument("--min_nodes", type=int, default=MIN_NODES,
                        help="The minimum healthy nodes to keep in the upstream group")
    parser.add_argument("--max_nodes", type=int, default=MAX_NODES,
                        help="The maximum nodes to keep in the upstream group, healthy or unhealthy")
    parser.add_argument("--max_nodes_to_add", type=int, default=MAX_NODES_TO_ADD,
                        help="The maximum nodes to add at one time")
    parser.add_argument("--max_nodes_to_remove", type=int, default=MAX_NODES_TO_REMOVE,
                        help="The maximum nodes to remove at one time")
    parser.add_argument("--min_rps", type=int, default=MIN_RPS,
                        help="The rps per node below which to scale down")
    parser.add_argument("--max_rps", type=int, default=MAX_RPS,
                        help="The rps per node above which to scale up")
    global args
    args = parser.parse_args()

    if args.verbose:
        print("Input arguments:")
        print("args: " + str(args))

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
        nginxStats = getStatus(client, args.nginx_status_url, "")

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
            nodeCounts = getNodeCounts(client, args.nginx_status_url, args.nginx_upstream_group)
            totalNodes = nodeCounts['totalNodes']
            upNodes = nodeCounts['upNodes']
            if args.verbose:
                print("upNodes=%d") %(upNodes)

            # If upNodes is 0 then there are no active nodes, in which case
            # no traffic can be flowing and no scaling based on traffic can
            # be needed.
            if upNodes > 0:
                # Calculate the requests per second per backend node
                rpsPerNode = rps / upNodes
                neededNodes = math.ceil(rps / args.max_rps)
                if rpsPerNode > args.max_rps:
                    # Scale up unless the maximum nodes has been reached
                    if totalNodes < args.max_nodes:
                        # Make sure to add at least one node
                        newNodeCount = min(neededNodes - upNodes, args.max_nodes_to_add, args.max_nodes - totalNodes)
                        #print("Scale up %d nodes") %(newNodeCount)
                        print("Scale up by %d nodes from %d to %d nodes") %(newNodeCount, totalNodes, totalNodes + newNodeCount)
                        addBackendNodes(newNodeCount)
                else:
                    if rpsPerNode < args.min_rps:
                        # Scale down unless the minimum nodes has been reached
                        if upNodes > args.min_nodes:
                            removeNodeCount = min(upNodes - neededNodes, args.max_nodes_to_remove, upNodes - args.min_nodes)
                            print("Scale down by %d nodes from %d nodes to %d nodes") %(removeNodeCount, totalNodes, totalNodes - removeNodeCount)
                            removeBackendNodes(removeNodeCount)

            # Make sure the number of healthy nodes hasn't dropped below the minimum
            if upNodes < args.min_nodes:
                if args.verbose:
                    print("up nodes %d has fallin below the minimum nodes %d") %(upNodes, args.min_nodes)
                newNodeCount = min(args.min_nodes - upNodes, args.max_nodes_to_add, args.max_nodes - totalNodes)
                print("Scale up by %d nodes from %d to %d nodes") %(newNodeCount, totalNodes, totalNodes + newNodeCount)
                addBackendNodes(newNodeCount)
        else:
            lastSeconds = currentSeconds
            lastRequests = currentRequests

        time.sleep(args.sleep_interval)

if __name__ == '__main__':
	main()
