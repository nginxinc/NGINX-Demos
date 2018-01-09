<?php
/*******************************************************************************
* hcheck.php
*
* Copyright (C) 2017 Nginx, Inc.
* This page is provided for demonstration purposes only
*
* Checks the percentage of CPU usage.  The threshold defaults to 70%.  It is
* specified as the total allowed for all containers.  This is divided by the
* number of upstream nodes to get the threshold allowed for each container.
*
* The threshold can be set with the "threshold" query parameter.
*
* If the CPU usage is below the per node threshold, return
*     {" HealthCheck":"OK","CPUUsage":<cpu usage percent>,
*      "Threshold":<total cpu usage threshold>,
*      "ThresholdPerNode":<cpu usage threshold per node>,
*      "Host":"<host name>"}
* otherwise return
*     {"HealthCheck":"CPU busy","CPUUsage":<cpu usage percent>,
*      "Threshold":<total cpu usage threshold>,
*      "ThresholdPerNode":<cpu usage threshold per node>,
*      "Host":"<host name>"}
*******************************************************************************/

define('TOTAL_THRESHOLD', 70);
define('DOCKER_API', 'dockerhost:2375');
define('STATUS_API', 'dockerhost:8082');

include('httpget.inc');

function GetCPUUsage($dockerAPI, $hostName) {
    $url = "http://$dockerAPI/containers/$hostName/stats?stream=0";
    try {
        $response = httpGet($url);
        if ($response["ResponseCode"] == 200) {
            $statsArray = json_decode($response["ResponseData"], true);
            $containerUsage1 = $statsArray["cpu_stats"]["cpu_usage"]["total_usage"];
            $systemUsage1 = $statsArray["cpu_stats"]["system_cpu_usage"];
            $response = httpGet($url);
            if ($response["ResponseCode"] == 200) {
                $statsArray = json_decode($response["ResponseData"], true);
                $containerUsage2 = $statsArray["cpu_stats"]["cpu_usage"]["total_usage"];
                $systemUsage2 = $statsArray["cpu_stats"]["system_cpu_usage"];
                $containerUsageDiff = $containerUsage2 - $containerUsage1;
                $systemUsageDiff = $systemUsage2 - $systemUsage1;
                $cpuPercent = 0.0;
                if ($systemUsageDiff > 0 && $containerUsageDiff > 0) {
                    $cpuPercent = round((($containerUsageDiff /
                                          $systemUsageDiff)
                                          * sizeof($statsArray["cpu_stats"]["cpu_usage"]["percpu_usage"]))
                                          * 100, 1);
                }
                return $cpuPercent;
            } else {
                throw new Exception('Error getting Docker stats: ' . $response->code);
            }
        } else {
            throw new Exception('Error getting Docker stats: ' . $response->code);
        }
    } catch  (Exception $e) {
        throw new Exception('Error getting Docker stats: ' . $e);
    }
}

function GetUpstreamCount($statusAPI, $upstreamGroup) {
    $url = "http://$statusAPI/api/2/http/upstreams/$upstreamGroup";

    try {
        $response = httpGet($url);
        if ($response["ResponseCode"] == 200) {
            $upstreamArray = json_decode($response["ResponseData"], true);
            $upstreamCount = 0;
            foreach ($upstreamArray['peers'] as $key => $upstreamData) {
                if ($upstreamData['state'] != 'down') {
                    $upstreamCount++;
                }
            }
            return $upstreamCount;
        } else {
            throw new Exception('Error getting NGINX Plus stats: ' . $response->code);
        }
    } catch  (Exception $e) {
        throw new Exception('Error getting Docker stats: ' . $e);
    }
}

/********* Main *********/

$hostName = gethostname();

if (isset($_GET["threshold"]) && is_numeric($_GET["threshold"]) &&
    $_GET["threshold"] > 0 && $_GET["threshold"] < 100) {
    $totalThreshold = $_GET["threshold"];
} else {
    $totalThreshold = TOTAL_THRESHOLD;
}

$upstreamCount = getUpstreamCount(STATUS_API, "unitcpu");
$thresholdPerNode = round($totalThreshold / $upstreamCount, 0);
$cpuUsage = GetCPUUsage(DOCKER_API, $hostName);

if ($cpuUsage < $thresholdPerNode) {
    print('{"HealthCheck":"OK","CPUUsage":' . $cpuUsage . ',"TotalThreshold":' . $totalThreshold . ',"ThresholdPerNode":' . $thresholdPerNode . ',"Host":"' . $hostName . '"}'. "\n");
} else {
    print('{"HealthCheck":"CPU Busy","CPUUsage":' . $cpuUsage . ',"TotalThreshold":' . $totalThreshold . ',"ThresholdPerNode":' . $thresholdPerNode. ',"Host":"' . $hostName . '"}'. "\n");
}

?>
