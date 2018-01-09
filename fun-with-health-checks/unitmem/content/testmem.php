<?php
/*******************************************************************************
* testmem.php
*
* Copyright (C) 2017 Nginx, Inc.
* This program is provided for demonstration purposes only
*
* Causes high memory usage.  After allocating memory it sleeps for the number
* of seconds specified in the “sleep" GET variable, defaulting to 10.
*******************************************************************************/

class Node {
    public $parentNode;
    public $childNodes = array();
    function Node() {
        $this->nodeValue = str_repeat('0123456789', 1000);
    }
}

function createRelationship() {
    $parent = new Node();
    $child = new Node();
    $parent->childNodes[] = $child;
    $child->parentNode = $parent;
}

$start = time();

$sleep=10;
$hostName = gethostname();

$loops=10000;

if (isset($_GET['sleep']) && is_numeric($_GET['sleep'])) {
    $sleep=$_GET['sleep'];
}

for($i = 0; $i < $loops; $i++) {
    createRelationship();
}

sleep($sleep);

$elapsed = time() - $start;

print('{"Status":"Memory test completed in ' . $elapsed . ' seconds","Host":"' . $hostName . '"}' . "\n");
?>
