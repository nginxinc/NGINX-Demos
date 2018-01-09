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

include_recipe "nginx::#{node['nginx']['install_source']}"

service 'nginx' do
  supports status: true, restart: true, reload: true
  action   :start
end

include_recipe 'nginx::configs'

include_recipe 'nginx::amplify-agent' if node['nginx']['amplify_api_key'] != nil
