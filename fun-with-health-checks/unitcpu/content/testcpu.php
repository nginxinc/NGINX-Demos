<?php
/*******************************************************************************
* testcpu.php
*
* Copyright (C) 2017 Nginx, Inc.
* This program is provided for demonstration purposes only
*
* Call stress to generate CPU load.  It runs in a loop for 1 second each time
* until the number of seconds specified in the "timeout" GET variable has
* elapsed, defaulting to 10.  stress is run for 1 second each time and the
* --backoff parameter is used to adjust the amount of CPU usage generated.
* The "level" GET variable is used to specify how much CPU to generate. It
* can have a value from 1 to 6 with larger numbers indicating more CPU usage.
* The default value is 4.  The backoff value be set to 500000 for level 1,
* 400000 for level 2 and so on until it is set to 0 for level 6.
*******************************************************************************/

$start = time();

$timeout = 10;
$level = 4;
$hostName = gethostname();

if (isset($_GET['timeout']) && is_numeric($_GET['timeout'])) {
    $timeout=$_GET['timeout'];
}

if (isset($_GET['level']) && is_numeric($_GET['level'])) {
    if ($_GET['level'] >= 1 && $_GET['level'] <= 6) {
        $level=$_GET['level'];
    }
}

$backoff = (6 - $level) * 100000;

while (true) {
    $elapsed = time() - $start;
    if ($elapsed >= $timeout) {
        break;
    }
    $out = shell_exec("stress -c 1 -m 1 -t 1 --backoff $backoff");
}

$elapsed = time() - $start;
print("level=$level  backoff=$backoff\n"); #DEBUG
print('{"Status":"CPU test completed in ' . $elapsed . ' seconds","Host":"' . $hostName . '"}'. "\n");
?>
