#!/bin/sh

# create an instance
gcloud compute instances create nginxplus \
  --machine-type n1-standard-1 \
  --image ubuntu-14-04 \
  --tags lb \
  --boot-disk-size 10 --boot-disk-type pd-ssd

# wait for 1 minute for the machine to be brough up
sleep 60s

# copy the certificate and the key and the installation script and nginx conf
gcloud compute copy-files nginx-repo.crt nginx-repo.key  \
  nginxplus_installation_script.sh meetup.conf  nginx-stackdriver.conf \
  stackdriver-plugin.conf udp.conf nginxplus:

# run the installation script
gcloud compute ssh nginxplus --command "sh ./nginxplus_installation_script.sh"

# Add a firewall rule to allow 80 and 8080
gcloud compute firewall-rules create lb-rule --allow udp:5683,tcp:8080 \
  --source-ranges "0.0.0.0/0" --target-tags lb
