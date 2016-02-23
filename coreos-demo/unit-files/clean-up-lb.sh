#!/bin/bash

fleetctl destroy loadbalancer@1 && fleetctl destroy loadbalancer-discovery\@1
