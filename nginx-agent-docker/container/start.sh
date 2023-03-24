#!/bin/bash

nginx
sleep 2

PARM="--server-grpcport $NIM_GRPC_PORT --server-host $NIM_HOST"

if [[ ! -z "$NIM_INSTANCEGROUP" ]]; then
   PARM="${PARM} --instance-group $NIM_INSTANCEGROUP"
fi

if [[ ! -z "$NIM_TAGS" ]]; then
   PARM="${PARM} --tags $NIM_TAGS"
fi


if [[ "$NAP_WAF" == "true" ]]; then
   PARM="${PARM} --nginx-app-protect-report-interval 15s --nap-monitoring-collector-buffer-size 50000 --nap-monitoring-processor-buffer-size 50000 --nap-monitoring-syslog-ip 127.0.0.1 --nap-monitoring-syslog-port 514"
   su - nginx -s /bin/bash -c "/opt/app_protect/bin/bd_agent &"
   su - nginx -s /bin/bash -c "/usr/share/ts/bin/bd-socket-plugin tmm_count 4 proc_cpuinfo_cpu_mhz 2000000 total_xml_memory 471859200 total_umu_max_size 3129344 sys_max_account_id 1024 no_static_config &"

   while ([ ! -e /opt/app_protect/pipe/app_protect_plugin_socket ] || [ ! -e /opt/app_protect/pipe/ts_agent_pipe ])
   do
     sleep 1
   done

   chown nginx:nginx /opt/app_protect/pipe/*
fi

if [[ "$NAP_WAF_PRECOMPILED_POLICIES" == "true" ]]; then
   PARM="${PARM} --nginx-app-protect-precompiled-publication"
fi

if [[ "$ACM_DEVPORTAL" == "true" ]]; then
   nginx-devportal server &
fi

sg nginx-agent "/usr/bin/nginx-agent $PARM"
