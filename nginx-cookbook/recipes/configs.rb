#
# Cookbook Name:: nginx
# Recipe:: configs
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
