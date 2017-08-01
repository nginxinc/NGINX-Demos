#!/bin/bash

# Slightly modified versions of the following code blocks are currently used
# as startup and shutdown scripts for Google Cloud instance templates
# They provide a good reference on how to query Google Cloud for LB and App IPs 
# and update the Nginx upstream API with those values

# Get list of available upstreams
curl 'http://localhost/upstream_conf?upstream=upstream_app_pool'

# Loop through IPs of available LBs and APPs
gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --regexp=.*lb.* | while read -r lb; do
  gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --regexp=.*app.* | while read -r app; do
    # curl -s 'http://'"$lb"'/upstream_conf?add=&upstream=upstream_app_pool&server='"$app"'';
    # echo "LB: $lb && APP: $app"
  done;
done;

# Loop through IPs of available LBs and APPs
lbip=$(gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --regexp=.*lb.*)
arrlb=($lbip)
appip=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --regexp=.*app.*)
arrapp=($appip)
for (( i=0; i < ${#arrlb[@]}; i++ )); do
  for (( j=0; j < ${#arrapp[@]}; j++ )); do
    # curl 'http://'"${arrlb[i]}"'/upstream_conf?add=&upstream=upstream_app_pool&server='"${arrapp[j]}"'';
    # echo "LB: ${arrlb[i]} && APP: ${arrapp[j]}"
  done;
done;

# Add all app servers not in the upstream to the current LB server
# Check if app server is already present and if not add to LB
appip=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --regexp=.*app.*)
arrapp=($appip)
for (( i=0; i < ${#arrapp[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://localhost/upstream_conf?upstream=upstream_app_pool' | grep -Eo 'server ([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
  upstrarr=($upstrlist)
  for (( j=0; j < ${#upstrarr[@]}; j++ )); do
    if [ "${arrapp[i]}" = "${upstrarr[j]}" ]; then
      is_present=true;
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -s 'http://localhost/upstream_conf?add=&upstream=upstream_app_pool&server='"${arrapp[i]}"'';
  fi;
done;

# Get the internal IP of the current app server and add this server to the upstream of all LB instances
# Check if app server is already present and if not add to LB
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
lbip=$(gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --regexp=.*lb.*)
arrlb=($lbip)
for (( i=0; i < ${#arrlb[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://'"${arrlb[i]}"'/upstream_conf?upstream=upstream_app_pool' | grep -Eo 'server ([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
  upstrarr=($upstrlist)
  for (( j=0; j < ${#upstrarr[@]}; j++ )); do
    if [ "$inip" = "${upstrarr[j]}" ]; then
      is_present=true;
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -s 'http://'"${arrlb[i]}"'/upstream_conf?add=&upstream=upstream_app_pool&server='"$inip"'';
  fi;
done;

# Get the internal IP of the current app server and delete this server from the upstream of all LB instances
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --regexp=.*lb.* | while read -r lb; do
  for ID in $(curl -s 'http://'"$lb"'/upstream_conf?upstream=upstream_app_pool' | grep -o 'server '"$inip"':80; # id=[0-9]\+' | grep -o 'id=[0-9]\+' | grep -o '[0-9]\+'); do
    curl 'http://'"$lb"'/upstream_conf?remove=&upstream=upstream_app_pool&id='"$ID"'';
  done;
done;

# Get a list of Upstream servers and loop through them to delete them
gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --regexp=.*lb.* | while read -r lb; do
  for ID in $(curl -s 'http://'"$lb"'/upstream_conf?upstream=upstream_app_pool' | grep -o 'id=[0-9]\+' | grep -o '[0-9]\+'); do
    curl 'http://'"$lb"'/upstream_conf?remove=&upstream=upstream_app_pool&id='"$ID"'';
  done;
done;
