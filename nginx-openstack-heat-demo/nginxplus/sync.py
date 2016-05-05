import requests
import time
import logging
import json

logging.basicConfig(format='%(asctime)s %(message)s', level=logging.INFO)

BACKEND_PORT = 80
RESYNC_PERIOD_IN_SECONDS = 10

def get_backends_from_metadata_server():
    r = requests.get('http://169.254.169.254/openstack/latest/meta_data.json')
    s = r.json()['meta']['backends']
    return parse_backends_string(s)


def parse_backends_string(str):
    # "[\"10.0.0.42\", \"10.0.0.41\"]" -> ["10.0.0.42", "10.0.0.41"]
    # "[\"10.0.0.42\"]" -> ["10.0.0.42"]
    # "[]" -> []
    s = str.replace('\\', '').replace('"[', '[').replace(']"', '')

    return json.loads(s)

def get_backends_in_nginx():
    r = requests.get('http://127.0.0.1:8080/status/upstreams/backend')

    backends = []
    id_to_backend = {}

    for server in r.json()['peers']:
        backends.append(server['server'])
        id_to_backend[server['server']] = server['id']

    return (backends, id_to_backend)

def delete_backends_from_nginx(backends, id_to_backend):
    for backend in backends:
        r = requests.get('http://127.0.0.1:8080/upstream_conf?upstream=backend&remove=&id={}'.format(id_to_backend[backend]))
        logging.info(r.text)


def add_backends_to_nginx(backends):
    for backend in backends:
        r = requests.get('http://127.0.0.1:8080/upstream_conf?upstream=backend&add=&server={}'.format(backend))
        logging.info(r.text)

def sync():
    backends = get_backends_from_metadata_server()

    # add a port to each IP address: 10.0.0.1 -> 10.0.0.1:80
    backends = ['{}:{}'.format(ip, BACKEND_PORT) for ip in backends]

    # convert to a set
    backends = set(backends)

    logging.info('backends: {}'.format(backends))

    (backends_in_nginx, id_to_backend) = get_backends_in_nginx()
    backends_in_nginx = set(backends_in_nginx)

    logging.info('backens in NGINX: {}'.format(backends_in_nginx))

    backends_to_delete = backends_in_nginx - backends
    backends_to_add = backends - backends_in_nginx

    logging.info('backends to delete from NGINX: {}'.format(backends_to_delete))
    delete_backends_from_nginx(backends_to_delete, id_to_backend)

    logging.info('baceknds to add to NGINX: {}'.format(backends_to_add))
    add_backends_to_nginx(backends_to_add)


def main():
    while True:
        sync()
        time.sleep(RESYNC_PERIOD_IN_SECONDS)



if __name__ == '__main__':
    main()
