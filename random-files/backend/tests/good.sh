#!/bin/bash

if [ $RANDOM -gt 10000 ]; then
	echo good;
	exit 0;
fi

echo bad;
exit 1;


