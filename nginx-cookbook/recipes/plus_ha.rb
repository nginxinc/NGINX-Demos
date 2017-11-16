#
# Cookbook Name:: nginx
# Recipe:: plus_ha
# Author:: Damian Curry <damian.curry@nginx.com>
#
# Copyright 2008-2013, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
