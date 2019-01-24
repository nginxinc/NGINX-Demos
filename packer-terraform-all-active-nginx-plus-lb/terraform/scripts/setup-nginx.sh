#!/bin/bash

# Slightly modified versions of the following code blocks are currently used
# as startup and shutdown scripts for Google Cloud instance templates.
# They provide a good reference on how to query Google Cloud for
# NGINX load balancer and application server instance IPs and how to update the
# NGINX upstream REST API with those values.

# The following script can be used by NGINX load balancer instances to check for
# application servers and add them to the NGINX load balancer upstream servers
# list. For this script to work the application server needs to include 'app'
# as part of its name.

# Get IP of local machine
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
# Get list of all application server instances IP and format list as an array
appip=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name~'.*app.*'")
arrapp=($appip)
# Loop through all application IPs
for (( i=0; i < $${#arrapp[@]}; i++ )); do
  is_present=false;
  # Get list of all upstream server instances in this NGINX load balancer
  # and format list as an array
  upstrlist=$(curl -s 'http://localhost:8080/api/3/http/upstreams/upstream_app_pool/servers' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3})"
  upstrarr=($upstrlist)
  # Loop through all upstream IPs and check whether the application IP is
  # already present in the upstream list
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    # Do nothing if application IP is already included in the upstream list
    if [ "$${arrapp[i]}" = "$${upstrarr[j]}" ]; then
      is_present=true;
      echo "Server $${upstrarr[j]} is already contained in the $inip upstream group"
    fi;
  done;
  # Add application IP to upstream list if application IP is not already
  # included in the upstream list
  if [ "$is_present" = false ]; then
    curl -X POST -d '{"server": "'"$${arrapp[i]}"'"}' -s 'http://localhost:8080/api/3/http/upstreams/upstream_app_pool/servers';
    echo "Server $${upstrarr[j]} has been added to the $inip upstream group"
  fi;
done;

# The following script can be used by application server instances to add their
# IP to all NGINX load balancer upstream server lists. For this script to work
# the load balancer server needs to include 'lb' as part of its name.

# Get IP of local machine
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
# Get list of all load balancer server instances IP and format list as an array
lbip=$(gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --filter="name~'.*lb.*'")
arrlb=($lbip)
# Loop through all load balancer IPs
for (( i=0; i < $${#arrlb[@]}; i++ )); do
  is_present=false;
  # Get list of all upstream server instances in each NGINX load balancer
  # and format list as an array
  upstrlist=$(curl -s 'http://'"$${arrlb[i]}"':8080/api/3/http/upstreams/upstream_app_pool/servers' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
  upstrarr=($upstrlist)
  # Loop through all upstream IPs and check whether the application IP is
  # already present in the upstream list
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    # Do nothing if application IP is already included in the upstream list
    if [ "$inip" = "$${upstrarr[j]}" ]; then
      is_present=true;
      echo "Server $${upstrarr[j]} is already contained in the $inip upstream group"
    fi;
  done;
  # Add application IP to upstream list if application IP is not already
  # included in the upstream list
  if [ "$is_present" = false ]; then
    curl -X POST -d '{"server": "'"$inip"'"}' -s 'http://'"$${arrlb[i]}"':8080/api/3/http/upstreams/upstream_app_pool/servers';
    echo "Server $${upstrarr[j]} has been added to the $inip upstream group"
  fi;
done;

# The following script can be used by application server instances to remove
# their IP from all NGINX load balancer upstream server lists. For this script
# to work the load balancer server needs to include 'lb' as part of its name.

# Get IP of local machine
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
# Get list of all load balancer server instances IP and format list as an array
gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --filter="name~'.*lb.*'"| while read -r lb; do
  # Loop through all load balancers and remove the application server IP from
  # the upstream servers list
  for ID in $(curl -s 'http://'"$lb"':8080/api/3/http/upstreams/upstream_app_pool/servers' | grep -o '"id":[0-9]\+\','"server":"10.138.0.2:80"' | grep -o '"id":[0-9]\+' | grep -o '[0-9]\+'); do
    curl -X DELETE -s 'http://'"$lb"':8080/api/3/http/upstreams/upstream_app_pool/servers/'"$ID"'';
    echo "Server $inip has been removed from $lb upstream group"
  done;
done;
