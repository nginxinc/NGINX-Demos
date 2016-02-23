#!/bin/bash

fleetctl list-units | awk '$1 ~ /^backend@/ {print $1}' | xargs fleetctl destroy
fleetctl list-units | awk '$1 ~ /^backend-discovery@/ {print $1}' | xargs fleetctl destroy
