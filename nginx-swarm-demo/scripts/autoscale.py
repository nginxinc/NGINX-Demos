#!/usr/bin/env python
################################################################################
# Copyright (C) 2016 Nginx, Inc.
#
# Version 0.5.0 2016/08/24
#
# This program is provided for demonstration purposes only
#
# A proof of concept for auto-scaling an NGINX Plus upstream group
# in Docker Swarm.
#
# This script periodically makes a request to the NGINX Plus status API
# and computes the request rate based on the number of requests that have
# been processed since the last API call and the number of nodes, both up
# and total in the upstream group.  If the request rate per up node is above
# the specified maximum request rate, one or more nodes will be added to
# the upstream group using the Docker Swarm CLI, unless the maximum number
# of total nodes has been reached.  If the request rate per up node is below
# the specified limit, one or more nodes will be removed from the upstream
# group unless the minimum number of nodes has been reached.
#
# The settings that control the autoscaling behavior can be set on the command
# or the default values can be used.  -h or --help will print out the complete
# list of command line parameters.
################################################################################

import requests
import sys
import time
import datetime
import os
import math
import argparse
from docker import Client

# Default values for command line arguments to control the autoscaling behavior

SWARM_MASTER = 'swarmmaster' # The host name for the Swarm master node
DOCKER_API_PORT = 2375 # The port for the HTTP Docker API
SERVICE = 'service1' # The Docker Swarm Service and upstream group to scale
NGINX_STATUS_PATH = 'status' # The URL path for the NGINX Plus status API
NGINX_STATUS_PORT = 8081 # The port for the NGINX Plus status API
SERVER_ZONE = 'swarmdemo' # The server zone to get the number of requests from

SLEEP_INTERVAL = 5 # How long to wait between API requests, in seconds
MIN_NODES = 2 # Minimum number of nodes to maintain in the upstream group
MAX_NODES = 10 # Maximum number of nodes to allow in the upstream group
MAX_NODES_TO_ADD = 2 # Maximum number of nodes to be added at one time
MAX_NODES_TO_REMOVE = 2 # Maximum number of nodes to be remove at one time
MIN_RPS = 4 # Scale down if the requests per second falls below this value
MAX_RPS = 6 # Scale up if the requests per second exceeds this value

################################################################################
# Function getStatus
#
# Make a call to the NGINX Plus Status API.
################################################################################
def getStatus(client, swarmMaster, statusPath, statusPort, path):

    url = 'HTTP://' + swarmMaster + ':' + str(statusPort) + '/' + statusPath + path

    try:
        response = client.get(url) # Make an NGINX Plus status API call
    except requests.exceptions.ConnectionError:
        print("Error: Unable to connect to " + url)
        sys.exit(1)

    if response.status_code == 200:
        return response.json()
    else:
        print("Error: url=%s status=%d") %(url, response.status_code)
        sys.exit(1)

################################################################################
# Function scaleBackendNodes
#
# Add or remove one or more backends to the upstream group.
################################################################################
def scaleBackendNodes(swarmService, nodeCount):

    cmd = 'docker service scale ' + swarmService + '=' + str(int(nodeCount))
    os.system(cmd)

################################################################################
# Function getRequestCount
#
# Use the Status API to the total request count from the server zone.
################################################################################
def getRequestCount(serverZone, nginxStats):
	return nginxStats['server_zones'][serverZone]['requests']

################################################################################
# Function getNodeCounts
#
# Use the Status API to count the total number of nodes in the upstream group
# and the number that are currently up.
################################################################################
def getNodeCounts(client, swarmMaster, statusPath, statusPort, upstreamGroup):

    path = '/upstreams/' + upstreamGroup + '/peers'
    totalCount = 0
    upCount = 0

    nginxStats = getStatus(client, swarmMaster, statusPath, statusPort, path)
    for stats in nginxStats:
        totalCount += 1
        if stats['state'] == 'up':
            upCount += 1

    nodeCounts = { 'totalNodes' : totalCount, 'upNodes' : upCount }
    return nodeCounts

################################################################################
# Function getReplicaCount
#
# Use the Docker API to get the count of containers for a service.
################################################################################
def getReplicaCount(client, swarmMaster, dockerAPIPort, serviceName):

    url = '/services/' + serviceName
    cli = Client(base_url='unix://var/run/docker.sock')
    serviceData = cli.services({'name': serviceName})
    nodeCount = serviceData[0]['Spec']['Mode']['Replicated']['Replicas']

    #serviceData = getDocker(client, swarmMaster, dockerAPIPort, url)
    #nodeCount = serviceData['Spec']['Mode']['Replicated']['Replicas']

    return nodeCount

################################################################################
################################################################################
## Main
################################################################################
################################################################################

def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Provide more detailed output")
    parser.add_argument("--swarm_master", default=SWARM_MASTER,
                        help="Host name or IP address of the Swarm Master node")
    parser.add_argument("--docker_api_port", type=int, default=DOCKER_API_PORT,
                        help="HTTP port for the Docker API")
    parser.add_argument("-s", "--service", default=SERVICE,
                        help="The Swarm service and NGINX Plus upstream group to scale")
    parser.add_argument("--nginx_status_path", default=NGINX_STATUS_PATH,
                        help="URL for NGINX Plus Status API")
    parser.add_argument("--nginx_status_port", type=int, default=NGINX_STATUS_PORT,
                        help="Port for the NGINX Plus Status API")
    parser.add_argument("--nginx_server_zone", default=SERVER_ZONE,
                        help="The NGINX Plus server zone to collect requests count from")
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

    syncErrorCount = 0

    while True:
        now = datetime.datetime.now()
        currentSeconds= (now.hour * 60) + (now.minute * 60) + now.second
        nginxStats = getStatus(client, args.swarm_master, args.nginx_status_path, args.nginx_status_port, "")

        # Get the total number nodes in the upstream group, and the total that
        # that are currently up.  Do the RPS calculation on the up nodes, but
        # still respect the total allowed nodes.
        nodeCounts = getNodeCounts(client, args.swarm_master, args.nginx_status_path, args.nginx_status_port, args.service)
        totalNodes = nodeCounts['totalNodes']
        upNodes = nodeCounts['upNodes']

        # Get the number of containers for the service
        replicaCount = getReplicaCount(client, args.swarm_master, args.docker_api_port, args.service)

        currentRequests = getRequestCount(args.nginx_server_zone, nginxStats)
        print("currentRequests=%d lastSeconds=%d") %(currentRequests, lastSeconds) #DEBUG

        print("NGINX Total Nodes=%d Up Nodes=%d Replicas=%d") %(totalNodes, upNodes, replicaCount) #DEBUG
        # If totalNodes isn't equal to replicatCount then Docker must be
        # updating.  Try again on the next loop iteration.
        if totalNodes != replicaCount:
            syncErrorCount += 1
            if syncErrorCount == 1:
                print("NGINX Plus shows %d nodes and Docker shows %d containers.  Wait for Docker to update") %(totalNodes, replicaCount)
                time.sleep(args.sleep_interval)
                lastSeconds = currentSeconds
                lastRequests = currentRequests
                continue
            else:
                print("NGINX Plus shows %d nodes and Docker shows %d containers.  Continue") %(totalNodes, replicaCount)
        else:
            syncErrorCount = 0

        if lastSeconds > 0:
            # calculate how many seconds have elapsed since the last API request
            interval = currentSeconds - lastSeconds
            # Calculate the total requests per second since the last API request
            rps = (currentRequests - lastRequests) / float(interval)
            lastSeconds = currentSeconds
            lastRequests = currentRequests

            # If upNodes is 0 then either there are no nodes, in which case
            # no traffic can be flowing and no scale up can be needed or there
            # was a problem getting the node information.
            if upNodes > 0:
                # Calculate the requests per second per backend node
                rpsPerNode = rps / upNodes
                neededNodes = math.ceil(rps / float(args.max_rps))
                if args.verbose:
                    print("rps=%d rpsPerNode=%d neededNodes=%d") %(rps, rpsPerNode, neededNodes)
                if rpsPerNode > args.max_rps:
                    # Scale up unless the maximum nodes has been reached
                    if totalNodes < args.max_nodes:
                        # Make sure to add at least one node
                        newNodeCount = min(neededNodes - upNodes, args.max_nodes_to_add, args.max_nodes - totalNodes)
                        if newNodeCount > 0:
                            print("Scale up by %d nodes from %d to %d nodes") %(newNodeCount, totalNodes, totalNodes + newNodeCount)
                            scaleBackendNodes(args.service, totalNodes + newNodeCount)
                        else:
                            print("Warning: newNodeCount=%d on scale up event") %(newNodeCount)
                    else:
                        if args.verbose:
                            print("totalNodes %d not less than maximum nodes %d") %(totalNodes, args.max_nodes)
                else:
                    if rpsPerNode < args.min_rps:
                        # Scale down unless the minimum nodes has been reached
                        if upNodes > args.min_nodes:
                            removeNodeCount = min(upNodes - neededNodes, args.max_nodes_to_remove, upNodes - args.min_nodes)
                            if removeNodeCount > 0:
                                print("Scale down by %d nodes from %d nodes to %d nodes") %(removeNodeCount, totalNodes, totalNodes - removeNodeCount)
                                scaleBackendNodes(args.service, totalNodes - removeNodeCount)
                            else:
                                print("Warning: removeNodeCount=%d on scale down event") %(removeNodeCount)
                        else:
                            if args.verbose:
                                print("upNodes %d not greater than minimum nodes %d") %(upNodes, args.min_nodes)
                    else:
                        if args.verbose:
                            print("rpsPerNode %f in between minRPS %d and maxRPS %d") %(rpsPerNode, args.min_rps, args.max_rps)

        else:
            lastSeconds = currentSeconds
            lastRequests = currentRequests

        time.sleep(args.sleep_interval)

if __name__ == '__main__':
	main()
