################################################################################
# testcnt.pyp
#
# Copyright (C) 2017 Nginx, Inc.
# This program is provided for demonstration purposes only
#
# There are two modes:
#   1. Acts as the application, creating the busy file, then sleeping for the
#      number of seconds specified in the "sleep" GET variable, defaulting to
#      10, then removes the busy file.
#   2. Does the health check by checking for the existence of the file
#      "/tmp/busy". If it is found return
#        {"HealthCheck":"Busy","Host":"<host name>"}
#      otherwise return
#        {"HealthCheck":"OK","Host":"<host name>"}.
#
#   The first mode is the default.  The 2nd mode is only executed if the
#   "healthcheck" GET variable is passed in.
################################################################################

import os
import datetime
import time

def application(environ, start_response):

    mode = 'testcnt'
    busyFile = '/tmp/busy'
    hostName = os.environ['HOSTNAME']

    if 'QUERY_STRING' in environ:
        queryString = str(environ['QUERY_STRING'])
        queryStringValues = queryString.split("=", 1)
        if queryStringValues[0] == 'sleep':
            try:
                n = int(queryStringValues[1])
                sleepSecs = n
            except ValueError:
                pass
        elif queryStringValues[0] == 'healthcheck':
            mode = 'healthcheck'

    if mode == 'testcnt':
        sleepSecs = 10

        startTime = datetime.datetime.now()

        if 'QUERY_STRING' in environ:
            queryString = str(environ['QUERY_STRING'])
            queryStringValues = queryString.split("=", 1)
            if queryStringValues[0] == 'sleep':
                try:
                    n = int(queryStringValues[1])
                    sleepSecs = n
                except ValueError:
                    pass

        if os.path.isfile(busyFile):
            start_response('503 Service Unavailable', [('Content-type', 'text/plain')])
            return

        f = open(busyFile,"w+")
        f.close

        time.sleep(sleepSecs)

        if os.path.isfile(busyFile):
            os.remove(busyFile)

        elapsed = datetime.datetime.now() - startTime
        elapsedSecs = int(elapsed.total_seconds())

        output = '{"Status":"Count test completed in ' + str(elapsedSecs) + ' seconds","Host":"' + hostName + '"}' + "\n"

        start_response('200 OK', [('Content-type', 'text/plain')])
        return [output]
    else:
        if os.path.isfile(busyFile):
            output = '{"HealthCheck":"Busy","Host":"' + hostName + '"}' + "\n"
        else:
            output = '{"HealthCheck":"OK","Host":"' + hostName + '"}' + "\n"

        start_response('200 OK', [('Content-type', 'text/plain')])
        return [output]
