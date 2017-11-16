#
# Cookbook Name:: nginx
# Recipe:: plus
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
