#!/bin/bash

NUMBER_OF_NODES=3
SLEEP_INTERVAL_IN_SECONDS=5

for i in $(seq 1 $NUMBER_OF_NODES)
do
   fleetctl start backend@$i
   fleetctl start backend-discovery@$i
#   sleep $SLEEP_INTERVAL_IN_SECONDS
done

fleetctl list-units
