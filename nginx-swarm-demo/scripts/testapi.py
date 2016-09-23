#!/usr/bin/env python

import requests
import sys
import time
import datetime
import os
import math
import argparse

from docker import Client

try:
    client = Client(base_url='unix://var/run/docker.sock')
except:
    print("Error on client create:", sys.exc_info()[0])
    sys.exit(1)

print("client created")

try:
    serviceList = client.services()
except:
    print("Error on service list:", sys.exc_info()[0])
    sys.exit(1)

print("services: " + str(serviceList))

try:
    service1Data = client.inspect_service('service1')
    #service1Data = client.inspect_service(service='service1')
except:
    print("Error on inspect service:", sys.exc_info()[0])
    sys.exit(1)

print("service1: " + str(service1Data))

svcId = service1Data['ID']
print("svcId: " + svcId)

version = client.inspect_service(svcId)['Version']['Index']
print("version: %d") %(version)

try:
    client.update_service(svcId, version, replicas=4)
except:
    print("Error on service update:", sys.exc_info()[0])
    sys.exit(1)

print("Service updated")
