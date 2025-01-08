#!/bin/bash

if [[ `whoami` == "nginx" ]]; then
  IS_UNPRIVILEGED="true"
else
  IS_UNPRIVILEGED=
fi

if [[ ! -z "$NGINX_LICENSE" ]]; then
   echo ${NGINX_LICENSE} > /etc/nginx/license.jwt
fi

nginx
sleep 2

if [[ "$NGINX_AGENT_ENABLED" == "true" ]]; then

  # NGINX Agent version detection, change in behaviour in v2.24.0+
  AGENT_VERSION=`nginx-agent -v|awk '{print $3}'`
  AGENT_VERSION_MAJOR=`echo $AGENT_VERSION | awk -F\. '{print $1}' | sed 's/v//'`
  AGENT_VERSION_MINOR=`echo $AGENT_VERSION | awk -F\. '{print $2}'`

  echo "=> NGINX Agent version $AGENT_VERSION"

  PARM=""

  yq -i '
    .server.host=strenv(NGINX_AGENT_SERVER_HOST) |
    .server.grpcPort=strenv(NGINX_AGENT_SERVER_GRPCPORT) |
    .tls.enable=true |
    .tls.skip_verify=true |
    .tls.cert="" |
    .tls.key=""
    ' /etc/nginx-agent/nginx-agent.conf

  if [[ ! -z "$NGINX_AGENT_INSTANCE_GROUP" ]]; then
     PARM="${PARM} --instance-group $NGINX_AGENT_INSTANCE_GROUP"
  fi

  if [[ ! -z "$NGINX_AGENT_TAGS" ]]; then
     PARM="${PARM} --tags $NGINX_AGENT_TAGS"
  fi

  if [[ ! -z "$NGINX_AGENT_SERVER_TOKEN" ]]; then
    yq -i '
      .server.token=strenv(NGINX_AGENT_SERVER_TOKEN)
      ' /etc/nginx-agent/nginx-agent.conf
  fi

  if [[ ! -z "$NGINX_AGENT_LOG_LEVEL" ]]; then
    yq -i '
      .log.level=strenv(NGINX_AGENT_LOG_LEVEL)
      ' /etc/nginx-agent/nginx-agent.conf
  fi
fi

if [[ "$NAP_WAF" == "true" ]]; then
  export FQDN=127.0.0.1

  yq -i '
    .nap_monitoring.collector_buffer_size=50000 |
    .nap_monitoring.processor_buffer_size=50000 |
    .nap_monitoring.syslog_ip=strenv(FQDN) |
    .nap_monitoring.syslog_port=514 |
    .extensions += ["nginx-app-protect","nap-monitoring"]
    ' /etc/nginx-agent/nginx-agent.conf

  if [[ "$IS_UNPRIVILEGED" ]]; then
    /opt/app_protect/bin/bd_agent &
    /usr/share/ts/bin/bd-socket-plugin tmm_count 4 proc_cpuinfo_cpu_mhz 2000000 total_xml_memory 471859200 total_umu_max_size 3129344 sys_max_account_id 1024 no_static_config &
  else
    su - nginx -s /bin/bash -c "/opt/app_protect/bin/bd_agent &"
    su - nginx -s /bin/bash -c "/usr/share/ts/bin/bd-socket-plugin tmm_count 4 proc_cpuinfo_cpu_mhz 2000000 total_xml_memory 471859200 total_umu_max_size 3129344 sys_max_account_id 1024 no_static_config &"
  fi

  while ([ ! -e /opt/app_protect/pipe/app_protect_plugin_socket ] || [ ! -e /opt/app_protect/pipe/ts_agent_pipe ])
  do
    sleep 1
  done

  chown nginx:nginx /opt/app_protect/pipe/*

if [[ "$NAP_WAF_PRECOMPILED_POLICIES" == "true" ]]; then
  yq -i '
    .nginx_app_protect.precompiled_publication=true
    ' /etc/nginx-agent/nginx-agent.conf
fi

fi

if [[ "$NGINX_AGENT_ENABLED" == "true" ]]; then
  if [[ "$IS_UNPRIVILEGED" ]]; then
    /usr/bin/nginx-agent $PARM
  else
    sg nginx-agent "/usr/bin/nginx-agent $PARM"
  fi
else
  while [ true ]; do sleep 3600; done
fi
