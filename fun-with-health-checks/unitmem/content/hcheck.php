<?php
/*******************************************************************************
* hcheck.php
*
* Copyright (C) 2017 Nginx, Inc.
* This program is provided for demonstration purposes only
*
* Checks the percentage of used memory.  By default the threshold is 70%, but
* this can be overridden using the "threshold" query parameter.
*
* If the memory usage percentage is above the threshold return:
*     {"HealthCheck":"OK","MemUsedPercent":<used percent>,"MemUsed":<used>,
*      "MemLimit":<limit>,"Threshold":<threshold>,"Host":"<hostname>"}
*
* otherwise return
*     {"HealthCheck":"Memory low","MemUsedPercent":<used percent>,
*      "MemUsed":<used>,"MemLimit":<limit>,"Threshold":<threshold>,
*      "Host":"<host name>"}
*
* If there is an error return:
*     {"HealthCheck":"Error","Info":"Error getting memory data",
*      "Host":"<host name>"}
*******************************************************************************/

include('httpget.inc');

define('THRESHOLD', 70);
define('DOCKER_API', 'dockerhost:2375');

function getDockerStats($dockerAPI, $hostName) {
    $url = "http://$dockerAPI/containers/$hostName/stats?stream=0";
    try {
        $response = httpGet($url);
        if ($response["ResponseCode"] == 200) {
            $statsArray = json_decode($response["ResponseData"], true);
            $limit = $statsArray["memory_stats"]["stats"]["hierarchical_memory_limit"];
            $usage = $statsArray["memory_stats"]["usage"];
            $percent = round(($usage / $limit) * 100, 1);
            return Array("limit"=>$limit, "usage"=>$usage, "percent"=>$percent);
        } else {
            throw new Exception('Error getting stats: ' . $response->code);
        }
    } catch  (Exception $e) {
        throw new Exception('Error getting stats: ' . $e);
    }
}

/********* Main *********/

$hostName = gethostname();

if (isset($_GET["threshold"]) && is_numeric($_GET["threshold"]) &&
    $_GET["threshold"] > 0 && $_GET["threshold"] < 100) {
    $threshold = $_GET["threshold"];
} else {
    $threshold = THRESHOLD;
}

try {
    $stats = getDockerStats(DOCKER_API, $hostName);
    $memUsed = round($stats['usage'] / 1024 / 1024, 1);
    $memLimit = round($stats['limit'] / 1024 / 1024, 0);
    if ($stats['percent'] < $threshold) {
        print('{"HealthCheck":"OK","MemUsedPercent":' . $stats['percent'] .
              ',"MemUsed":' . $memUsed . ',"MemLimit":' . $memLimit .
              ',"Threshold":' . $threshold .
              ',"Host":"' . "$hostName" . '"}'. "\n");
    } else {
        print('{"HealthCheck":"Memory low","MemUsedPercent":' . $stats['percent'] .
              ',"MemUsed":' . $memUsed . ',"MemLimit":' . $memLimit .
              ',"Threshold":' . $threshold .
              ',"Host":"' . "$hostName" . '"}'. "\n");
    }
} catch  (Exception $e) {
    print('{"HealthCheck":"Error", "Info":"Error getting memory data",' .
            '"Host":"' . "$hostName" . '"}'. "\n");
}
?>
