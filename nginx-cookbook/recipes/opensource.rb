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
