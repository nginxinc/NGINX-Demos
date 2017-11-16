#
# Cookbook Name:: nginx
# Recipe:: amplify
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

case node['platform_family']
when 'rhel'
  version_long = node[:platform_version]
  version = version_long[0]

  yum_repository 'amplify-agent' do
    description "NGINX Amplify Agent"
    baseurl "https://packages.amplify.nginx.com/centos/#{version}/$basearch"
    gpg_key "http://nginx.org/keys/nginx_signing.key"
  end

  yum_package 'nginx-amplify-agent' do
    flush_cache before: true
  end

when 'debian'
  #include_recipe 'apt::default'

  apt_repository 'amplify-agent' do
    uri          'https://packages.amplify.nginx.com/ubuntu'
    distribution node['lsb']['codename']
    components   %w(amplify-agent)
    deb_src      false
    key          'https://nginx.org/keys/nginx_signing.key'
  end

  remote_file '/etc/apt/apt.conf.d/90nginx' do
    source 'https://cs.nginx.com/static/files/90nginx'
    owner 'root'
    group 'root'
    mode 0644
    notifies :update, 'apt_update[enable nginx-plus]', :immediate
  end
  #include_recipe 'apt'
  apt_update 'enable nginx-plus' do
    action :nothing
  end

  apt_package 'nginx-amplify-agent' do
    action :install
  end
end

template 'etc/amplify-agent/agent.conf' do
  source 'amplify-agent.conf.erb'
  owner  'nginx'
  group  node['root_group']
  mode   '0644'
  notifies :restart, 'service[amplify-agent]', :delayed
end

service 'amplify-agent' do
  supports status: true, restart: true, start: true, stop: true
  action   :start
end
