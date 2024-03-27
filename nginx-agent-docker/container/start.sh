#!/bin/bash

nginx
sleep 2

# NGINX Agent version detection, change in behaviour in v2.24.0+
AGENT_VERSION=`nginx-agent -v|awk '{print $3}'`
AGENT_VERSION_MAJOR=`echo $AGENT_VERSION | awk -F\. '{print $1}' | sed 's/v//'`
AGENT_VERSION_MINOR=`echo $AGENT_VERSION | awk -F\. '{print $2}'`

echo "=> NGINX Agent version $AGENT_VERSION"

PARM=""

yq -i '
  .server.host=strenv(NIM_HOST) |
  .server.grpcPort=strenv(NIM_GRPC_PORT)
  ' /etc/nginx-agent/nginx-agent.conf

if [[ ! -z "$NIM_INSTANCEGROUP" ]]; then
   PARM="${PARM} --instance-group $NIM_INSTANCEGROUP"
fi

if [[ ! -z "$NIM_TAGS" ]]; then
   PARM="${PARM} --tags $NIM_TAGS"
fi

if [[ ! -z "$NIM_TOKEN" ]]; then
      yq -i '
	.server.token=strenv(NIM_TOKEN)
	' /etc/nginx-agent/nginx-agent.conf
fi

if [[ "$NIM_ADVANCED_METRICS" == "true" ]]; then
	yq -i '
	.advanced_metrics.socket_path="/var/run/nginx-agent/advanced-metrics.sock" |
	.advanced_metrics.aggregation_period="1s" |
	.advanced_metrics.publishing_period="3s" |
	.advanced_metrics.table_sizes_limits.staging_table_max_size=1000 |
	.advanced_metrics.table_sizes_limits.staging_table_threshold=1000 |
	.advanced_metrics.table_sizes_limits.priority_table_max_size=1000 |
	.advanced_metrics.table_sizes_limits.priority_table_threshold= 1000 |
	.extensions += ["advanced-metrics"]
	' /etc/nginx-agent/nginx-agent.conf
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

  su - nginx -s /bin/bash -c "/opt/app_protect/bin/bd_agent &"
  su - nginx -s /bin/bash -c "/usr/share/ts/bin/bd-socket-plugin tmm_count 4 proc_cpuinfo_cpu_mhz 2000000 total_xml_memory 471859200 total_umu_max_size 3129344 sys_max_account_id 1024 no_static_config &"

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

sg nginx-agent "/usr/bin/nginx-agent $PARM"
