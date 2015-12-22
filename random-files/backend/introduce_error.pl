#!/usr/bin/perl

# This script introduces some random error to illustrate how health check works
#
# Select a random container
#
# Break a page in that container with wrong codepage
#
# Usage: ./introduce_error.pl [CONTAINER-NAME]

if (!scalar(@ARGV)) {
	print "Usage: ./introduce_error.pl [CONTAINER-NAME]\n";
	print "\nExiting...\n";
	exit 1;
}

$container = $ARGV[0];

$cmd = "docker exec " . $container . " mv /usr/share/nginx/html/index_cn.html /usr/share/nginx/html/index.html";

print $cmd;
print "\n\n";

system $cmd;

