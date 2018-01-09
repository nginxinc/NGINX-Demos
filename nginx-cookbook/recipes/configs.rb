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

directory '/etc/nginx/conf.d' do
  owner 'root'
  group node['root_group']
  mode  '0755'
end

file '/etc/nginx/conf.d/default.conf' do
  action :delete
  notifies :reload, 'service[nginx]', :delayed
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  owner  'root'
  group  node['root_group']
  mode   '0644'
  notifies :reload, 'service[nginx]', :delayed
end

if node['nginx']['plus_status_enable'] == true
  template '/etc/nginx/conf.d/nginx_plus_status.conf' do
    source 'status.conf.erb'
    owner  'root'
    group  node['root_group']
    mode   '0644'
    notifies :reload, 'service[nginx]', :delayed
  end
end
