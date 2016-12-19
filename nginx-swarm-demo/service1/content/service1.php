<!DOCTYPE html>
<html>
<head>
<title>Hello from Service 1</title>

<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Hello from Service 1</h1>
<h2>URI: <?php print($_SERVER['REQUEST_URI']) ?></h2>
<h2>My hostname: <?php print($_SERVER['HTTP_HOST']) ?></h2>
<h2>My address: <?php print($_SERVER['SERVER_ADDR']) ?></h2>
-------------------------------------------------------------
<h1>From Service 2:</h1><br>

<?php
include('httpful.phar');

$url='http://nginxplus/service2.php';

try {
    $response = \Httpful\Request::get($url)->send();
    print("$response\n");
} catch  (Exception $e) {
    print("Error: ");
    var_dump($e);
    print("\n");
}

?>
