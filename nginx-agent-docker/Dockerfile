FROM centos:7

ARG NMS_URL
ARG DEVPORTAL=false
ARG NAP_WAF=false

# Initial packages setup
RUN yum -y update \
	&& yum install -y wget ca-certificates epel-release curl \
# NGINX Instance Manager agent setup
	&& mkdir -p /deployment /etc/ssl/nginx \
# Agent installation
	&& bash -c 'curl -k $NMS_URL/install/nginx-agent | sh' && echo "Agent installed from NMS"

# Startup script
COPY ./container/start.sh /deployment/

# Download certificate and key from the customer portal (https://account.f5.com)
# and copy to the build context
RUN --mount=type=secret,id=nginx-crt,dst=/etc/ssl/nginx/nginx-repo.crt \
	--mount=type=secret,id=nginx-key,dst=/etc/ssl/nginx/nginx-repo.key \
	set -x \
# Startup script
	&& chmod +x /deployment/start.sh && touch /.dockerenv \
# Install prerequisite packages:
	&& yum -y update \
	&& yum autoremove -y \
	&& yum -y clean all \
	&& rm -rf /var/cache/yum \
	&& wget -P /etc/yum.repos.d https://cs.nginx.com/static/files/nginx-plus-7.4.repo \
	&& yum install -y nginx-plus nginx-plus-module-njs nginx-plus-module-prometheus \

# Optional NGINX App Protect WAF
	&& if [ "$NAP_WAF" = "true" ] ; then \
	wget -P /etc/yum.repos.d https://cs.nginx.com/static/files/app-protect-7.repo \
	&& yum install -y app-protect app-protect-attack-signatures; fi \

# Optional API Connectivity Manager DevPortal
	&& if [ "$DEVPORTAL" = "true" ] ; then \
	wget -P /etc/yum.repos.d https://cs.nginx.com/static/files/nms.repo \
	&& curl -o /tmp/nginx_signing.key https://nginx.org/keys/nginx_signing.key \
	&& rpmkeys --import /tmp/nginx_signing.key \
	&& yum -y update \
	&& yum -y install nginx-devportal nginx-devportal-ui \
	&& echo 'DB_TYPE="sqlite"' | tee -a /etc/nginx-devportal/devportal.conf \
	&& echo 'DB_PATH="/var/lib/nginx-devportal"' | tee -a /etc/nginx-devportal/devportal.conf; fi \

# Forward request logs to Docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80
STOPSIGNAL SIGTERM

CMD /deployment/start.sh
