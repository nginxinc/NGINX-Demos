# Copyright (C) 2016 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Defines constants needed by the other scripts
#

# dockerHost defines host name for the swarm master.
#
# dockerPrefix specifies the value to prefix the Docker images with.  If all the
# images are to be pushed and pulled from a private DockerHub repo, the
# recommended approach, this value much be set to
#     dockerPrefix="DOCKERHUB_USER/REPO_NAME:"
#
# For example, if the DockerHub user is "mydockehub" and the name of the repo
# is "swarmdemo":
#   
#    dockerPrefix="mydockerhub/swarmdemo:"
# 
# If all images will be built and stored on each server, then  the value 
# should be left blank.
#
# It shoudl be possible to use a local private repo, in which case this value
# should be set to the host name and port, but this has not been tested. 
#
# checkDockerLogin defines whether the user must be logged into DockerHub 
# when pushing or pulling images.  If a local private repo is used, this
#  should be set to "no" to disable the check.

demoHost="swarmmaster"

dockerPrefix=""

checkDockerLogin="yes"
