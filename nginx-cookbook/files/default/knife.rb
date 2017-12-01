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

current_dir                   = File.dirname(__FILE__)
log_level                     :info
log_location                  STDOUT
node_name                     ""
client_key                    "#{current_dir}/<>.pem"
chef_server_url               "https://api.chef.io/organizations/nginx"
cookbook_path                 ["#{current_dir}/../cookbooks"]

# AWS variables
knife[:aws_access_key_id]     = ""
knife[:aws_secret_access_key] = ""
knife[:region]                = ""

# OpenStack variables
knife[:openstack_auth_url]    = ""
knife[:openstack_username]    = ""
knife[:openstack_password]    = ""
knife[:openstack_tenant]      = ""
knife[:openstack_flavor]      = ""
knife[:openstack_image]       = ""
knife[:openstack_ssh_key_id]  = ""
