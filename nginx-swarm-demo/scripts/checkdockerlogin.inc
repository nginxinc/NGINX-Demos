# Copyright (C) 2016 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Checks to make sure that if a DockerHub repository is
# used, that the user is logged in.  The check fails if
# dockerPrefix is not set.  If dockerPrefix is set but
# checkDockerLogin is set to "no" the check succeeds.
#
# Returns 0 if the check succeeds and 1 if it fails.

checkDockerLogin () {

    path="${BASH_SOURCE%/*}"

    dockerUser=$(grep dockerPrefix= $path/constants.inc | grep -v '^#' | awk -F[\",/] '{print $2}')
    if [ -z $dockerUser ]; then
        echo "Error: You must set "dockerPrefix" in constants.inc to be able $1 images"
        return 1
    fi
    dockerUser=`echo "$(set -f; echo $dockerUser)"` # Remove whitespace

    CheckDockerLogin=$(grep checkDockerLogin $path/constants.inc | awk -F= '{print $2}')
    if [ "$checkDockerLogin" = "no" ]; then
        return 0
    fi

    loggedInUser=$(docker info 2>/dev/null | grep Username | awk '{print $2}') &>/dev/null
    if [ "$dockerUser" = "$loggedInUser" ]; then
        return 0
    else
        echo "Error: You must be logged into DockerHub with user $dockerUser or you must"
        echo "       change the \"dockerPrefix\" value in constants.inc or disable this"
        echo "       check by setting checkDockerLogin to \"no\"."
        return 1
    fi
}
