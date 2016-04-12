#!/bin/sh

while true; do (echo abcdefghijklmnopqrstuvwxyz | nc -u -q 1 nginxplus 5683 &); sleep 0.04s; done;
