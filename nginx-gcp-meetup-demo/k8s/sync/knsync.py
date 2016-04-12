import requests
requests.packages.urllib3.disable_warnings()

import sys

NGINX_STATUS_AND_UPSRTEAM_ENDPOINT = sys.argv[1]
KUBERNETES_ENDPOINT = sys.argv[2]
KUBERNETES_TOKEN = sys.argv[3]



NGINX_STATUS_URL = NGINX_STATUS_AND_UPSRTEAM_ENDPOINT + '/status/stream/upstreams'
NGINX_UPSTREAM_GROUP = 'udp_backend'
NGINX_UPSTREAM_ADD_URL = NGINX_STATUS_AND_UPSRTEAM_ENDPOINT + '/upstream_conf?stream=&add=&upstream=' + NGINX_UPSTREAM_GROUP + '&server='
NGINX_UPSTREAM_DELETE_URL = NGINX_STATUS_AND_UPSRTEAM_ENDPOINT + '/upstream_conf?stream=&remove=&upstream='  + NGINX_UPSTREAM_GROUP + '&id='
KUBERNETES_ENDPOINTS_URL = KUBERNETES_ENDPOINT + '/api/v1/endpoints'

SERVICE_NAME_IN_KUBERNETES = 'backend-service'


serversToId = {}

def getNginxServers():
	r = requests.get(NGINX_STATUS_URL);
	data = r.json()

	nginxServersList = data[NGINX_UPSTREAM_GROUP]['peers']
	nginxServers = []

	for server in nginxServersList:
		nginxServers.append(server['server'])

		serversToId[server['server']] = server['id']

	return nginxServers


def addNginxServer(server):
	requests.get(NGINX_UPSTREAM_ADD_URL + server)
	print("server {} was added".format(server))


def addNginxServers(servers):
	for server in servers:
		addNginxServer(server)


def deleteNginxServer(server):
	id = serversToId[server]
	requests.get(NGINX_UPSTREAM_DELETE_URL + str(id));
	print("server {} was deleted".format(server))


def deleteNginxServers(servers):
	for server in servers:
		deleteNginxServer(server)


def getKubeServers():
	headers = {'Authorization': 'Bearer ' + KUBERNETES_TOKEN}
	r = requests.get(KUBERNETES_ENDPOINTS_URL, verify=False, headers=headers)
	data = r.json()

	servers = []

	for item in data['items']:
		if item['metadata']['name'] == SERVICE_NAME_IN_KUBERNETES:
			if len(item['subsets']) > 0:
				subset = item['subsets'][0]
				for address in subset['addresses']:
					servers.append(address['ip'] + ':5683')
				break

	return servers


def main():
	nginxServers = set(getNginxServers())
	kubeServers = set(getKubeServers())


	serversToDelete = nginxServers - kubeServers
	serversToAdd = kubeServers - nginxServers


	addNginxServers(serversToAdd)
	deleteNginxServers(serversToDelete)



if __name__ == '__main__':
	main()
