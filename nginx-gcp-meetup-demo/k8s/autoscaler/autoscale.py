#!/usr/bin/env python3

import requests
import time
import sys

requests.packages.urllib3.disable_warnings()

NGINX_STATUS_AND_UPSRTEAM_ENDPOINT = sys.argv[1]
KUBERNETES_ENDPOINT = sys.argv[2]
KUBERNETES_TOKEN = sys.argv[3]


NGINX_UPSTREAM_GROUP = 'udp_backend'
NGINX_SERVER_ZONE = 'udp_server'

NGINX_STATUS_URL = NGINX_STATUS_AND_UPSRTEAM_ENDPOINT + '/status'

SLEEP_INTERVAL_IN_SECONDS = 2
MIN_CONNS = 10
MAX_CONNS = 20
MIN_SERVER_COUNT = 1
MAX_SERVER_COUNT = 10



KUBERNETES_ENDPOINTS_URL = KUBERNETES_ENDPOINT + '/api/v1/endpoints'
KUBERNETES_RC_URL = KUBERNETES_ENDPOINT + '/api/v1/namespaces/default/replicationcontrollers/'


KUBERNETES_RC_NAME = 'backend'


def getNginxServerCount(statusData):
	peers = statusData['stream']['upstreams'][NGINX_UPSTREAM_GROUP]['peers']

	return len(peers)



def getNginxConns(statusData):
	return statusData['stream']['server_zones'][NGINX_SERVER_ZONE]['connections']


def addBackendIstance():
	instances = getTheNumberOfBackendInstances();
	setTheNumberOfBackendInstances(instances + 1)
	print('an instances has been added')


def removeBackendInstance():
	instances = getTheNumberOfBackendInstances();
	setTheNumberOfBackendInstances(instances - 1)
	print('an instances has been removed')


def getTheNumberOfBackendInstances():
	headers = {'Authorization': 'Bearer ' + KUBERNETES_TOKEN}
	r = requests.get(KUBERNETES_RC_URL + KUBERNETES_RC_NAME, verify=False,
		headers=headers)
	data = r.json()

	return data['spec']['replicas']


def setTheNumberOfBackendInstances(newNumber):
	headers = {'content-type': 'application/merge-patch+json',
		'Authorization': 'Bearer ' + KUBERNETES_TOKEN}
	jsonData = { "spec":  {"replicas": newNumber}}
	r = requests.patch(KUBERNETES_RC_URL + KUBERNETES_RC_NAME,
		verify=False, json=jsonData, headers=headers)


def main():
	lastConnsCount = -1


	while True:
		r = requests.get(NGINX_STATUS_URL);
		statusData = r.json();

		serverCount = getNginxServerCount(statusData)
		replicasCount = getTheNumberOfBackendInstances()
		currentConnsCount = getNginxConns(statusData)

		if (lastConnsCount != -1) and (replicasCount == serverCount):

			conns = (currentConnsCount - lastConnsCount) / SLEEP_INTERVAL_IN_SECONDS
			connsPerServer = conns / serverCount

			print("\nconns = {}".format(conns))
			print("conns per Server = {}".format(connsPerServer))
			print("server count = {}".format(serverCount))
			print("backend pods count = {}".format(replicasCount))

			if connsPerServer > MAX_CONNS:
				if serverCount < MAX_SERVER_COUNT:
					addBackendIstance()
			elif connsPerServer < MIN_CONNS:
				if serverCount > MIN_SERVER_COUNT:
					removeBackendInstance()

		if replicasCount != serverCount:
			print("\nWaiting for sync")


		lastConnsCount = currentConnsCount
		time.sleep(SLEEP_INTERVAL_IN_SECONDS)



if __name__ == '__main__':
	main()
