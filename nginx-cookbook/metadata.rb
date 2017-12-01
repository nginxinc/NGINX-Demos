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

name              'nginx'
maintainer        'Damian Curry'
maintainer_email  'damian.curry@nginx.com'
license           'Apache 2.0'
description       'Installs and configures NGINX and NGINX Plus'
version           '0.1.0'

source_url        'https://github.com/nginxinc/NGINX-Demos/tree/master/nginx-cookbook'

depends           'apt'
