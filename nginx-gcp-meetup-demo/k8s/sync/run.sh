#!/bin/sh

export KUBERNETES_API_ENDPOINT="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT"
export KUBERNETES_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

while true; do python3 knsync.py $1 $KUBERNETES_API_ENDPOINT $KUBERNETES_TOKEN; sleep 1; done