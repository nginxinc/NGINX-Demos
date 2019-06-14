<?php
/*******************************************************************************
* regextester.php
*
* Copyright (C) 2019 Nginx, Inc.
* This program is provided for NGINX internal use only
*
* It allows for testing regular expressions defined in an NGINX configuration.
* Locations or maps can be tested and matches can be case sensitive or
* insensitive.
*
* Positional capture groups are supported for both locations and maps, but named
* capture groups are only supported for maps.
*
* A base configuration file is used to serve this page, and a configuration
* file is generated for the regex testing.
*
* For locations, the user enters the regex and URI and an NGINX configuration
* file is generated and NGINX is reloaded.  The configuration file defines a
* virtual server listening on port 9000 with one location for / and another for
* the regex.  A request with the specified URI is sent to the virtual server.
* If the regex matches, that location will return a match message and display
* the capture groups, if any.  If the request goes to the / location a no-match
* message will be returned.
*
* For maps, the user enters the regex, value to be tested and the value to be
* set if a match is found.  An NGINX configuration file is generated and NGINX
* is reloaded.  The file defines a map and a location which generates a match
* message and the value that was set if a match is found and a no-match message
* if there was no match.
*******************************************************************************/
?>
<!DOCTYPE html>
<html>
<head>
    <title>NGINX Regular Expression Tester</title>
</head>
<body>
<center><h3>NGINX Regular Expression Tester</h3>
<br>
<?php

define('NGINX_URI', 'http://127.0.0.1:9000');
define('CONFIG_DIR', '/etc/nginx/conf.d');
define('CONFIG_FILE', 'regextest.conf');
define('LOC', 'loc');
define('MAP', 'map');

$locOrMap = LOC;
$regex = '';
$valueToTest = '';
$valueToSet = '';
$caseSensitive = 0;
$cbChecked = '';
$result = '';
$capture = '';
$errMsg = '';

# Location Config file to generate
$locConfig = <<<EOT
server {
    listen 9000;
    location / {
        return 200 "Match not found\\n";
    }
    location ~<*> <regex> {
        return 200 "Match found <capture>\\n";
    }
}

EOT;

# Map Config file to generate
$mapConfig = <<<EOT
map \$variable \$value {
    ~<*><regex> "Match found. Value set to: <value to set>";
    default "Match not found";
}

server {
    listen 9000;
    set \$variable "<value to test>";
    location / {
        return 200 "\$value\\n";
    }
}

EOT;

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $locOrMap = $_POST['locOrMap'];
    $regex = trim($_POST['frmRegex']);
    if (empty($regex)) {
        $errMsg = 'A regular expression must be entered. ';
    }
    $valueToTest = trim($_POST['frmValueToTest']);
    if (isset($_POST['frmCaseSensitive'])) {
        $caseSensitive = 1;
    }
    if ($caseSensitive) {
        $cbChecked = "checked";
    }
    if ($locOrMap == LOC) {
        # Remove leading / if entered
        $valueToTest = ltrim($valueToTest, '/');
        if (empty($valueToTest)) {
            $errMsg = $errMsg . 'A URI must be entered. ';
        }
    } else {
        if (empty($valueToTest)) {
            $errMsg = $errMsg . 'A value to test must be entered. ';
        }
        $valueToSet = trim($_POST['frmValueToSet']);
        if (empty($valueToSet)) {
            $errMsg = $errMsg . 'A value to set must be entered. ';
        }
    }
    if (empty($errMsg)) {
        try {
            if (!file_exists(CONFIG_DIR)) {
                if (!mkdir(CONFIG_DIR)) {
                    throw new Exception("Error creating directory " . CONFIG_DIR);
                }
            }
            $configTest = fopen(CONFIG_DIR . '/' . CONFIG_FILE, "w");
            if (!$configTest) {
                throw new Exception('Error opening file ' . CONFIG_DIR . '/' . CONFIG_FILE);
            }
            if ($locOrMap == LOC) {
                $openParens = substr_count ($regex, '(');
                $escOpenParens = substr_count ($regex, '\)');
                $captureGroups = $openParens - $escOpenParens;
                if ($caseSensitive) {
                    $locConfig = str_replace('<*>', '', $locConfig);
                } else {
                    $locConfig = str_replace('<*>', '*', $locConfig);
                }
                $locConfig = str_replace('<regex>', $regex, $locConfig);
                if ($captureGroups > 0) {
                    if ($captureGroups == 1) {
                        $capture = ' Capture Group';
                    } else {
                        $capture = ' Capture Groups';
                    }
                    for ($i = 1; $i <= $captureGroups; $i++) {
                        $capture .= " $i: \$$i";
                    }
                }
                $locConfig = str_replace('<capture>', $capture, $locConfig);
                $bytes = fwrite($configTest, $locConfig);
                if (!$bytes) {
                    $errMsg = 'Error writing config file.';
                }
            } else {
                # If the regex is in quotes, the ~ or ~* needs to go inside
                if (substr($regex, 0, 1) != '"') {
                    if ($caseSensitive) {
                        $mapConfig = str_replace('<*>', '', $mapConfig);
                    } else {
                        $mapConfig = str_replace('<*>', '*', $mapConfig);
                    }
                    $mapConfig = str_replace('<regex>', $regex, $mapConfig);
                } else {
                    if ($caseSensitive) {
                        $mapConfig = str_replace('~<*>', '"~', $mapConfig);
                    } else {
                        $mapConfig = str_replace('~<*>', '"~*', $mapConfig);
                    }
                    $mapConfig = str_replace('<regex>', ltrim($regex,'"'), $mapConfig);
                }
                $mapConfig = str_replace('<value to set>', $valueToSet, $mapConfig);
                $mapConfig = str_replace('<value to test>', $valueToTest, $mapConfig);
                $bytes = fwrite($configTest, $mapConfig);
                if (!$bytes) {
                    $errMsg = 'Error writing config file.';
                }
            }
            fclose($configTest);

            # Check config file syntax
            $cmdOut = shell_exec('nginx -t 2>&1');
            if (strpos($cmdOut, 'syntax is ok')) {
                $cmdOut = shell_exec('nginx -s reload 2>&1');
                if (!empty($cmdOut)) {
                    # Normally an empty string is returned, but occasionaly this string is returned
                    if (!strstr($cmdOut, 'signal process started')) {
                        $errMsg = "Error on nginx reload: $cmdOut";
                    }
                }
                sleep(1);
            } else {
                $errMsg = "There is an error in the configuration:\n$cmdOut\nCheck the regular expressions";
            }
        }
        catch(Exception $e) {
            $errMsg = 'Error creating config file: ' . $e->getMessage();
        }
        if (empty($errMsg)) {
            $result = file_get_contents(NGINX_URI . '/' . $valueToTest);
        }
    } else {
        if (!empty($errMsg)) {
            $errMsg = "Error: $errMsg";
        }
    }
} elseif ($_SERVER['REQUEST_METHOD'] == 'GET') {
    if (isset($_GET['test']) && $_GET['test'] == MAP) {
        $locOrMap = MAP;
    }
}
?>
<form action="" method="post">
    <input type="hidden" name="locOrMap" value="<?php print ($locOrMap)?>">
    <table cellpadding=2 cellspacing=2>
<?php
    if ($errMsg) {
        print("<tr>\n");
        print('<font color="red"><th align="right" valign="top">Error</th><td><textarea  rows="2" cols="80" readonly>' . $errMsg . "</textarea></td>\n");
        print("</tr>\n");
        print("<tr><td>&nbsp;</td></tr>\n");
    }
    if ($locOrMap == LOC) {
?>
        <tr>
            <th align="center" colspan="2">Location Tester</th>
        </tr>
        <td>&nbsp;</td></tr>
        <tr>
            <td align="center" colspan="2"><a href="regextester.php?test=map">Switch to the Map tester</a></td>
        </tr>
<?php
    } else {
?>
        <tr>
            <th align="center" colspan="2">Map Tester</th>
        </tr>
        <td>&nbsp;</td></tr>
        <tr>
            <td align="center" colspan="2"><a href="regextester.php?test=loc">Switch to the Location tester</a></td>
        </tr>
<?php
    }
?>
        <td>&nbsp;</td></tr>
        <tr>
            <th align="right">Regular Expression</th><td><input type="text" name="frmRegex" value='<?php print($regex);?>' size=80></td>
        </tr>
        <tr>
            <td></th><td><i>Enter the regular expression exactly as it will appear in the NGINX configuration,</i></td>
        </tr>
        <tr>
            <td></th><td><i>not including the '~' or '~*'.  If there are spaces in the regular expression, it</i></td>
        </tr>
        <tr>
            <td></th><td><i>must be enclosed in single or double quotes.</i></td>
        </tr>
        <tr><td>&nbsp;</td></tr>
        <tr>
            <th align="right">Case Sensitive</th><td><input type="checkbox" name="frmCaseSensitive" value="1" <?php print($cbChecked);?>></td>
        </tr>
        <tr><td>&nbsp;</td></tr>
<?php
    if ($locOrMap == LOC) {
?>
        <tr>
            <th align="right">URI</th><td>/<input type="text" name="frmValueToTest" value='<?php print($valueToTest);?>' size=80></td>
        </tr>
        <tr>
            <td></th><td><i>Enter the URI after the domain or IP address.</i></td>
        </tr>
        <tr>
            <td></th><td><i>For example, if the full URI is http://foo.com/abc/bar.ph, enter abc/bar.php.</i></td>
        </tr>
<?php
    } else {
?>
        <tr>
            <th align="right">Value to test</th><td><input type="text" name="frmValueToTest" value='<?php print($valueToTest);?>' size=80></td>
        </tr>
        <tr>
            <td></th><td><i>Enter the value to be evaluated by the Map</i></td>
        </tr>
        <tr><td>&nbsp;</td></tr>
        <tr>
            <th align="right">Value to set</th><td><input type="text" name="frmValueToSet" value='<?php print($valueToSet);?>' size=80></td>
        </tr>
        <tr>
            <td></th><td><i>Enter the value to be set by the Map if there is a match</i></td>
        </tr>
<?php
    }
?>
        <tr><td>&nbsp;</td></tr>
<?php
    if ($result != '') {
?>
        <tr>
            <th align="right" valign="top">Result</th><td><textarea  rows="2" cols="80" readonly><?php print($result);?></textarea></td>
        </tr>
        <tr><td>&nbsp;</td></tr>
<?php
        if ($locOrMap == LOC) {
            $config = $locConfig;
        } else {
            $config = $mapConfig;
        }
?>
        <tr>
            <th align="right" valign="top" rowspan="2">Generated<br>Configuration</th><td><textarea  rows="<?php print(substr_count($config, "\n") + 1);?>" cols="80" readonly><?php print($config);?></textarea></td>
        </tr>
        <tr><td>&nbsp;</td></tr>
<?php
    }
?>
        <tr>
            <td align="center" colspan="2"><input type="submit" value="Test"></td>
        </tr>
    </table>
</form>
</body>
</html>
