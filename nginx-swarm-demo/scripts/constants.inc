# Copyright (C) 2016 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# Defines constants needed by the other scripts
#

# dockerHost defines host name for the swarm master.
#
# dockerPrefix specifies the value to prefix the Docker images with.
# If the images are to be pushed and pulled from a DockerHub repo,
# this value much match the the DockerHub user.  If a private repo
# is used, this value must include the host name and port.  If all
# images will be stored in the local repo, the value can be left blank.
#
# If specified, the value must end with a trailing slash.  For
# example, if the DockerHub account is "nginxdemos" then dockerPrefix
# should be set to "nginxdemos/".
#
# checkDockerLogin defines whether the user must be logged into 
# DockerHub when pushing or pulling images.  If a private repo is
# used, this should be set to "no" to disable the check.

demoHost="swarmmaster"

dockerPrefix=""

checkDockerLogin="yes"
