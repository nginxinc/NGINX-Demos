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

nginx_host_ip = []
search(:node, "role:nginx_plus_autoscale") do |nodes|
  nginx_host_ip = nodes['ipaddress']
end

template "/usr/bin/autoscale_nginx.rb" do
  source "autoscale_nginx.rb.erb"
  owner 'root'
  group node['root_group']
  mode 0755
  variables(
    nginx_host: nginx_host_ip
  )
  #notifie service?
end

#cookbook_file "/root/.ssh/chef-demo.pem" do
cookbook_file "/home/ubuntu/.ssh/chef-demo.pem" do
  source "chef-demo.pem"
  owner 'ubuntu'
  group 'ubuntu'
  mode 0600
end

#directory "/root/.chef" do
directory "/home/ubuntu/.chef" do
  owner 'ubuntu'
  group 'ubuntu'
  mode 0755
end

#cookbook_file "/root/.chef/knife.rb" do
cookbook_file "/home/ubuntu/.chef/knife.rb" do
  source "knife.rb"
  owner 'ubuntu'
  group 'ubuntu'
  mode 0644
end

cookbook_file "/home/ubuntu/.chef/chef-key.pem" do
  source "chef-key.pem"
  owner 'root'
  group 'root'
  mode 0644
end

chef_gem "knife-ec2" do
  compile_time false if respond_to?(:compile_time)
  action :install
end
