#!/bin/sh

# create an instance
gcloud compute instances create loadgen \
  --machine-type n1-standard-1 \
  --image ubuntu-14-04 \
  --tags lb \
  --boot-disk-size 10 --boot-disk-type pd-ssd

# wait for 1 minute for the machine to be brough up
sleep 60s

# copy the load.sh
gcloud compute copy-files load.sh loadgen:
