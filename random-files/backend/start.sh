#!/bin/bash

# Run this with bash, not sh

echo 'body { background-color: rgb(' $(( (RANDOM % 255) )) ',' $(( (RANDOM % 255) )) ',' $(( (RANDOM % 255) )) '); }' > /usr/share/nginx/html/random.css

exec nginx -g "daemon off;"


