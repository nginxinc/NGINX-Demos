<!DOCTYPE html>
<html>
<head>
<title>Health check for Service 1</title>
<body>
<?php
include('httpful.phar');

$ip = $_SERVER['SERVER_ADDR'];

$url = "http://nginxplus:2379/v2/keys/$ip";

try {
    $response = \Httpful\Request::get($url)->send();
    # If a record for the IP Address is found in etcd then mark the server as unhealthy
    if ($response->code == '200') {
        print("Service 1: Status ERROR\n");
    } else {
        print("Service 1: Status OK\n");
    }
} catch  (Exception $e) {
    print("Error: ");
    var_dump($e);
    print("\n");
}
?>
