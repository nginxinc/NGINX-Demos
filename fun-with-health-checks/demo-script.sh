[bin/bash
# Copyright (C) 2017 Nginx, Inc.
#
# This program is provided for demonstration purposes only
#
# Runs the scripted commands for the busy-health-checks demo

cd "${BASH_SOURCE%/*}"

. demo-magic.sh

# speed at which to simulate typing. bigger num = faster
TYPE_SPEED=15

# custom prompt
DEMO_PROMPT="\u@\h:~# "

clear

#########################
##### Demo Script   #####
#########################

# 1. Show that there are no containers running
pe "docker ps"

# 2. Setup the environment
pe "docker-compose up -d"

# 3. Show that there are now containers running
pe "docker ps"

# 4. Show the NGINX Plus dashboard
# Browser: http://<docker host>:8082/dashboard.html#upstreams

# 5. Scale each of the Upstream Groups to have two containers
pe "docker-compose up --scale unitcnt=2 --scale unitcpu=2 --scale unitmem=2 -d"

# 6. Show that the dashboard reflects the new containers
# Browser

# 7. Show the count-based health check
pe "curl http://localhost:8001/testcnt.py?healthcheck"

# 8. Show the count-based health check again to see that
#    the requests are being load balanced
pe "curl http://localhost:8001/testcnt.py?healthcheck"

# 9. Show the CPU-usage-based health check
pe "curl http://localhost:8002/hcheck.php"

# 10. Show the memory-usage-based health check
pe "curl http://localhost:8003/hcheck.php"

# 11. Show the health check for one of the count-based
#     containers using the healthcheck path
# Shell: curl http://localhost/healthcheckpy?server=[Container IP:Port]

# 12. Make one of the count-based containers busy
pe "curl http://localhost:8001/testcnt.py"

# 13. Show the dashboard to see that the health check fails for one of the
#     count-based containers and wait to see it return to health.
# Browser

# 14. Show the failed health check for the busy containers
# Shell: curl http://localhost/healthcheckpy?server=[Container IP:Port]

# 15. After the container returns to health show the health check again
# Shell: curl http://localhost/healthcheckpy?server=[Container IP:Port]

# 16. Make both of the count-based containers busy
pe "curl http://localhost:8001/testcnt.py&"
TYPE_SPEED=250
pe "curl http://localhost:8001/testcnt.py&"

# 17. Show the dashboard to see that both count-based containers have
#     failed the health check.
# Browser

# 18. Show that you see the API busy page if you try to display the
#     testcnt.py page again
pe "curl http://localhost:8001/testcnt.py"
TYPE_SPEED=15

# 19. Scale down the cpu-usage-based Upstream Group to have one container 
pe "docker-compose up --scale unitcnt=2 --scale unitcpu=1 --scale unitmem=2 -d"

# 20. Run Docker stats
# Shell: docker stats

# 21. Send a request to one of the CPU-usage-based containers that uses less CPU than the threshold for one container (70%) but more then the thresshold for 2 containers (35%) 
pe "curl http://localhost:8002/testcpu.php"

# 22. Show Docker stats to see the CPU usage go up on one of the containers.
# Shell

# 23. Show the dashboard to see that none of the CPU-usage-based containers have failed the health check.
# Browser

# 24. Scale up the cpu-usage-based Upstream Group to have two container
pe "docker-compose up --scale unitcnt=2 --scale unitcpu=2 --scale unitmem=2 -d"

# 25. Send a request to one of the CPU-usage-based containers that uses more then the thresshold for 2 containers (35%) 
pe "curl http://localhost:8002/testcpu.php?timeout=45&"

# 26. Show Docker stats to see the CPU usage go up on one of the containers.
# Shell

# 27. Show the dashboard to see that one of the CPU-usage-based containers have failed the health check.
# Browser

# 28. Show the failed health check for the CPU-usage-based container
# Shell: curl http://localhost/healthcheck?server=[Container IP:Port]

# 29. Send a request to one of the CPU-usage-based containers that uses less CPU than the threshold (35%)
pe "curl http://localhost:8002/testcpu.php?level=2"

# 30. Show Docker stats to see the CPU usage go up on one of the containers.
# Shell

# 31. Show the dashboard to see that n0 additional CPU-usage-based containers have failed the health check.
# Browser

# 32. Make one of the memory-usage-based containers busy
pe "curl http://localhost:8003/testmem.php?sleep=15"

# 33. Show Docker stats to see the memory usage go up on one of the containers.
# Shell

# 34. Show the dashboard to see that one of the memory-usage-based
#     containers has failed the health check.
# Browser

# 35. Show the failed health check for the memory-usage-based container
# Shell: curl http://localhost/healthcheck?server=[Container IP:Port]

# show a prompt after the demo has concluded
p ""
