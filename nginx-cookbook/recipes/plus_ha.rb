#
# Cookbook Name:: nginx
# Attributes:: default
#
# Author:: Damian Curry (<damian.curry@nginx.com>)
#
# Copyright (c) 2017-present, NGINX, Inc.
#
# This source code is licensed under the Apache License (v2.0) found in the LICENSE file in
# the root directory of this source tree.
#

ha_pair_ips = []
# origip = "#{node[:ipaddress]}"
# search(:node, "role:nginx_plus_ha AND enable_ha_mode:#{node.nginx.enable_ha_mode} NOT name:#{node.name}") do |nodes|
#  ha_pair_ips << nodes["ipaddress"]
# end
# This is a work around for getting the eth1 IP that my VM's need, might have to rewrite when vagrant is brought into the mix. Above is the code the easy way.
origip = node[:network][:interfaces][:eth1][:addresses].detect { |_k, v| v[:family] == 'inet' }.first.to_s
search(:node, "role:nginx_plus_ha AND enable_ha_mode:#{node.nginx.enable_ha_mode} NOT name:#{node.name}") do |nodes|
  nodes['network']['interfaces']['eth1']['addresses'].each_pair do |address, value|
    ha_pair_ips << address if value.key?('broadcast')
  end
end

if node['name'].include? 'primary'
  ha_primary = 'true'
elsif node['name'].include? 'standby'
  ha_primary = 'false'
end

package 'nginx-ha-keepalived' do
  action :install
end

service 'keepalived' do
  supports status: true, restart: true, reload: true
  action   :enable
end
template '/etc/keepalived/keepalived.conf' do
  source 'keepalived.conf.erb'
  owner 'root'
  group node['root_group']
  mode '0644'
  variables(
    myip: origip,
    ha_pair_ip: ha_pair_ips
  )
  notifies :reload, 'service[keepalived]', :delayed
end
