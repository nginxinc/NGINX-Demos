NGINX Cookbook
==============
[![Cookbook]](https://github.com/NGINX-Demos/tree/master/nginx-cookbook)

This cookbook is for demonstration purposes only. The code contained herein is not intended for use in production.

Requirements
------------
### Cookbooks

- On RHEL family distros, the "yum" cookbook is required.
- On Debian family distros, the "apt" cookbook is required.

### Platforms

The following platforms are supported:
- Ubuntu
- CentOS

Other Debian and RHEL family distributions are assumed to work.

Attributes
----------
Node attributes for this cookbook are logically separated into different files. Some attributes are set only via a specific recipe.

### default
Generally used attributes. Some have platform-specific values. See `attributes/default.rb`. "The config" refers to "nginx.conf", the main config file.

- `node['nginx']['install_source']` - Defines where the package will be installed from, can be either 'plus' or 'opensource'. Defaults to 'opensource'.
- `node['nginx']['nginx_repo_crt']` - Defines a certificate to be used to access the NGINX Plus repositories.
- `node['nginx']['nginx_repo_key']` - Defines a certificate key to be used to access the NGINX Plus repositories.
- `node['nginx']['amplify_api_key']` - Defines an API key to authenticate with NGINX Amplify.  Setting this attribute will also trigger the Amplify agent to be installed.
- `node['nginx']['dir']` - Location for NGINX configuration.
- `node['nginx']['log_dir']` - Location for NGINX logs.
- `node['nginx']['pid']` - Location for the PID file.
- `node['nginx']['user']` - User that NGINX will run under.
- `node['nginx']['group']` - Group for NGINX.
- `node['nginx']['worker_processes']` - Number of worker processes that NGINX will spawn.  Defaults to auto, which sets the number equal to the number of CPU cores that the OS can see.
- `node['nginx']['worker_connections']` - Maximum number of simultaneous connections that can be opened by a worker process. Defaults to '1024'.
- `node['nginx']['tcp_nopush']` - Enables or disables the use of the TCP_NOPUSH socket option on FreeBSD or the TCP_CORK socket option on Linux. Defaults to false.
- `node['nginx']['enable_streams']` - Enables or disables the stream directive with an `include` directive. Defaults to false.
- `node['nginx']['stream_conf_dir']` - Sets directory and match string for the stream `include` statement.  Defaults to '/etc/nginx/streams-conf/*.conf'.

- `node['nginx']['plus_status_enable']` - Enables or disables the Plus-only extended status page.  Defaults to false.
- `node['nginx']['plus_status_port']` - Sets the port that the status page will listen on. Defaults to '8080'.
- `node['nginx']['plus_status_allowed_ips']` - Sets the list of IPs or IP ranges that have access to the status page. Defaults to nil.
- `node['nginx']['enable_upstream_conf']` - Enables the on-the-fly reconfiguration API for NGINX Plus. Defaults to false.
- `node['nginx']['plus_status_server_name']` - Sets the `server_name` directive used in the Plus status page. Defaults to 'status-page'.

- `node['nginx']['cloud_provider']` - Sets cloud provider to be used by the autoscaling script.  Currently supports ec2 (AWS) and openstack.




