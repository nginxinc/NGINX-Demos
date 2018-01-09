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
