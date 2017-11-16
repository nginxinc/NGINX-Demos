#
# Cookbook Name:: nginx
# Recipe:: opensource
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
  yum_repository 'nginx' do
    description 'NGINX Mainline Repo'
    baseurl "http://nginx.org/packages/mainline/#{node['platform']}/#{version}/$basearch/"
    gpgcheck false
    action :create
  end

when 'debian'
  #include_recipe 'apt::default'

  apt_repository 'nginx' do
    uri          "http://nginx.org/packages/mainline/#{node['platform']}/"
    distribution node['lsb']['codename']
    components   %w(nginx-plus)
    deb_src      false
    key          'http://nginx.org/keys/nginx_signing.key'
    notifies :update, 'apt_update[nginx update]', :immediate
  end

  apt_update 'nginx update' do
    action :nothing
    #subscribes :update, 'apt_repository[nginx]', :before
  end
end

package 'nginx' do
  not_if 'which nginx'
end
