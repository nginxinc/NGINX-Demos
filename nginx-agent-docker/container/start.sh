#!/bin/bash

nginx
sleep 2

# NGINX Agent version detection, change in behaviour in v2.24.0+
AGENT_VERSION=`nginx-agent -v|awk '{print $3}'`
AGENT_VERSION_MAJOR=`echo $AGENT_VERSION | awk -F\. '{print $1}' | sed 's/v//'`
AGENT_VERSION_MINOR=`echo $AGENT_VERSION | awk -F\. '{print $2}'`

echo "=> NGINX Agent version $AGENT_VERSION"

OLD_AGENT=false
if ([ $AGENT_VERSION_MAJOR -le 2 ] && [ $AGENT_VERSION_MINOR -lt 24 ])
then
	echo "=> Pre-v2.24 NGINX Agent detected"
	OLD_AGENT=true
fi

PARM="--server-grpcport $NIM_GRPC_PORT --server-host $NIM_HOST"

if [[ ! -z "$NIM_INSTANCEGROUP" ]]; then
   PARM="${PARM} --instance-group $NIM_INSTANCEGROUP"
fi

if [[ ! -z "$NIM_TAGS" ]]; then
   PARM="${PARM} --tags $NIM_TAGS"
fi

if [[ "$NIM_ADVANCED_METRICS" == "true" ]]; then
   if [ $OLD_AGENT == "false" ]
   then
      EXTRA_EXTENSIONS="- advanced-metrics"

      cat - << __EOT__ >> /etc/nginx-agent/nginx-agent.conf

# Advanced metrics
advanced_metrics:
  socket_path: /var/run/nginx-agent/advanced-metrics.sock
  aggregation_period: 1s
  publishing_period: 3s
  table_sizes_limits:
    staging_table_max_size: 1000
    staging_table_threshold: 1000
    priority_table_max_size: 1000
    priority_table_threshold: 1000
__EOT__
   fi
fi

if [[ "$NAP_WAF" == "true" ]]; then
   if [ $OLD_AGENT == "true" ]
   then
      PARM="${PARM} --nginx-app-protect-report-interval 15s --nap-monitoring-collector-buffer-size 50000 --nap-monitoring-processor-buffer-size 50000 --nap-monitoring-syslog-ip 127.0.0.1 --nap-monitoring-syslog-port 514"
   else
      EXTRA_EXTENSIONS=$EXTRA_EXTENSIONS"\n- nginx-app-protect\n- nap-monitoring"

      cat - << __EOT__ >> /etc/nginx-agent/nginx-agent.conf

# NGINX App Protect Monitoring config
nap_monitoring:
  # Buffer size for collector. Will contain log lines and parsed log lines
  collector_buffer_size: 50000
  # Buffer size for processor. Will contain log lines and parsed log lines
  processor_buffer_size: 50000
  # Syslog server IP address the collector will be listening to
  syslog_ip: "127.0.0.1"
  # Syslog server port the collector will be listening to
  syslog_port: 514
__EOT__
   fi

   su - nginx -s /bin/bash -c "/opt/app_protect/bin/bd_agent &"
   su - nginx -s /bin/bash -c "/usr/share/ts/bin/bd-socket-plugin tmm_count 4 proc_cpuinfo_cpu_mhz 2000000 total_xml_memory 471859200 total_umu_max_size 3129344 sys_max_account_id 1024 no_static_config &"

   while ([ ! -e /opt/app_protect/pipe/app_protect_plugin_socket ] || [ ! -e /opt/app_protect/pipe/ts_agent_pipe ])
   do
     sleep 1
   done

   chown nginx:nginx /opt/app_protect/pipe/*

if [[ "$NAP_WAF_PRECOMPILED_POLICIES" == "true" ]]; then
   if [ $OLD_AGENT == "true" ]
   then
      PARM="${PARM} --nginx-app-protect-precompiled-publication"
   else
      cat - << __EOT__ >> /etc/nginx-agent/nginx-agent.conf

# Enable NGINX App Protect WAF precompiled policies
nginx_app_protect:
  precompiled_publication: true
__EOT__
   fi
fi

fi

if [[ "$EXTRA_EXTENSIONS" != "" ]]; then
  cat - << __EOT__ >> /etc/nginx-agent/nginx-agent.conf

# Enable extensions
extensions:
`echo -e $EXTRA_EXTENSIONS | sed "s/^/\ \ /g"`
__EOT__
fi

sg nginx-agent "/usr/bin/nginx-agent $PARM"
