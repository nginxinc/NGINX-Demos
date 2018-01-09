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

directory '/etc/ssl/nginx' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

file '/etc/ssl/nginx/nginx-repo.key' do
  owner 'root'
  group 'root'
  mode 0644
  content node.attribute['nginx']['nginx_repo_key']
end

file '/etc/ssl/nginx/nginx-repo.crt' do
  owner 'root'
  group 'root'
  mode 0644
  content node.attribute['nginx']['nginx_repo_crt']
end

case node['platform_family']
when 'rhel'
  version_long = node[:platform_version]
  version = version_long[0]
  case version
  when '5'
    package 'openssl' do
      action :install
    end
  when '6', '7'
    package 'ca-certificates' do
      action :install
    end
  end

  remote_file "/etc/yum.repos.d/nginx-plus-#{version}.repo" do
    source "https://cs.nginx.com/static/files/nginx-plus-#{version}.repo"
    owner 'root'
    group 'root'
    mode 0700
  end

when 'debian'
  #include_recipe 'apt::default'

  apt_repository 'nginx_plus' do
    uri          'https://plus-pkgs.nginx.com/ubuntu'
    distribution node['lsb']['codename']
    components   %w(nginx-plus)
    deb_src      false
    key          'http://nginx.org/keys/nginx_signing.key'
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
end

package 'nginx-plus' do
  not_if 'which nginx'
end

include_recipe 'nginx::plus_ha' if node['nginx']['enable_ha_mode'] == 'true'
