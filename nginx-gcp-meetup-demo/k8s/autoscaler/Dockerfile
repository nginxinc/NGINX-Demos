FROM ubuntu:24.04
RUN apt-get update && apt-get install -y python3-pip && pip3 install requests --upgrade
COPY autoscale.py run.sh /
RUN ["chmod", "+x", "/run.sh"]
ENTRYPOINT ["/run.sh"]
