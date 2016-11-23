<!--
# Landing page/script to fully test load balancing
# and app server settings in an NGINX environment
# alan.murphy@nginx.com
--!>
<html>
<head>
<title>Welcome to nginx!</title>
</head>
<body>
<center>
<img src="images/nginx.png"><h1>
<?php echo 'Server: '.$_SERVER['SERVER_ADDR'].'<br>Port: '.$_SERVER['SERVER_PORT'];?></h1>
<h2><?php echo 'PHP Version: '.phpversion().'<br>';?></h2>
</center>
<h2>Welcome to nginx!</h2>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>

<h1>
HTTP Headers - Complete Dump Example PHP Script</h1>
<h3>How to use script:<br></h3>
<li>Test $_SERVER: Do nothing; script grabs existing $_SERVER headers, or manually add $_SERVER['HEADER'] = "test_data"; to script</li>
<li>Test $_GET: Append '?teststring=somevalue' to URI (POST submit button does this as well)</li>
<li>Test $_POST and $_REQUEST: Press Submit button below<br><br> 
    <form action="?post_success_get_header=true" method="post">
    <input type="hidden" name="post_success" value="True">
    <input type="submit" value="Submit Form">
    </form></li>
<li>Test $_SESSION: Update session_start code block</li>
<li>Test $_ENV: Make sure you set 'variables_order=EGPCS' in php.ini</li>
<li>Test $_COOKIE: Add new cookie to cookie code block</li>
<h2>Displays the following headers:</h2>
<li><a href="#server">$_SERVER</a></li>
<li><a href="#get">$_GET</a></li>
<li><a href="#post">$_POST</a></li>
<li><a href="#request">$_REQUEST</a></li>
<li><a href="#session">$_SESSION</a></li>
<li><a href="#env">$_ENV</a></li>
<li><a href="#cookie">$_COOKIE</a></li>
<li><a href="#response">$http_response_header</a></li>
<br>


<?php
/* http_headers.php - Simple php script to display all HTTP headers */

    /* Build various headers and context variables for later reading */

        /* Create new $_SERVER values just to test */
        if(empty($_SERVER['CONTENT_TYPE'])) {
            $_SERVER['CONTENT_TYPE'] = "application/x-www-form-urlencoded"; }

        if(empty($_SERVER['X-My-Header'])) {
            $_SERVER['X-My-Header'] = "Test String"; }

        /* Set test cookie to read $_COOKIE */ 
        $cookievalue = 'TEST_COOKIE';
        setcookie("TestCookie", $cookievalue);
    
        /* Create Session data for $_SESSION headers */
        session_start();
        $_SESSION['Session_Start_Time'] = date('l F jS Y h:i:s A');
        if(empty($_COOKIE['PHPSESSID'])) {
          $_SESSION['Session_Cookie'] = "PHPSESSID_NULL_Starting_Session"; }
        else {
          $_SESSION['Session_Cookie'] = $_COOKIE['PHPSESSID']; }
        session_destroy();

        if (PHP_MAJOR_VERSION >= 7) {
          session_reset();
        } else {
          session_unset();
        }

    /*Printing block to call all below functions and display on output */

        print "<h2><a name=server>\$_SERVER Headers:</h2><hr>" . PHP_EOL;
        foreach (getallserverheaders() as $servername => $servervalue) {
	    echo "<b>$servername:</b> $servervalue<br>";
        }  

        print "<h2><a name=get>\$_GET Headers:</h2><hr>" . PHP_EOL;
        foreach (getallgetheaders() as $getname => $getvalue) {
	    echo "<b>$getname:</b> $getvalue<br>";
        }  

        print "<h2><a name=post>\$_POST Headers:</h2><hr>" . PHP_EOL;
        foreach (getallpostheaders() as $postname => $postvalue) {
	    echo "<b>$postname:</b> $postvalue<br>";
        }  

        print "<h2><a name=request>\$_REQUEST Headers:</h2><hr>" . PHP_EOL;
        foreach (getallrequestheaders() as $requestname => $requestvalue) {
	    echo "<b>$requestname:</b> $requestvalue<br>";
        }  

        print "<h2><a name=session>\$_SESSION Headers:</h2><hr>" . PHP_EOL;
        foreach (getallsessionheaders() as $sessionname => $sessionvalue) {
	    echo "<b>$sessionname:</b> $sessionvalue<br>";
        }  

        print "<h2><a name=env>\$_ENV Headers:</h2><hr>" . PHP_EOL;
        foreach (getallenvheaders() as $envname => $envvalue) {
	    echo "<b>$envname:</b> $envvalue<br>";
        }  

        print "<h2><a name=cookie>\$_COOKIE Headers:</h2><hr>" . PHP_EOL;
        foreach (getallcookieheaders() as $cookiename => $cookievalue) {
	    echo "<b>$cookiename:</b> $cookievalue<br>";
        }  

        print "<h2><a name=response>http_response_header Headers:</h2><hr>" . PHP_EOL;
        foreach (getallresponseheaders() as $responsename => $responsevalue) {
	    echo "<b>$responsename:</b> $responsevalue<br>";
        }  
 
        /* Manual addition to print HTTP status code after header array */
        print "<b>" . count(getallresponseheaders()) . ": </b>HTTP Status Code = " . http_response_code();
 

    /*Build and define all functions. This is overkill for some array variables
      but should work on all web platforms for compatibility */

      #$_SERVER headers
      function getallserverheaders() {
        if (!is_array($_SERVER)) {
            return array();
        }
        $serverheaders = array();
        foreach ($_SERVER as $servername => $servervalue) {
                $serverheaders[$servername] = $servervalue;
            }
            return $serverheaders;
      }


      #$_GET headers
      function getallgetheaders() {
        if (!is_array($_GET)) {
            return array();
        }
        $getheaders = array();
        foreach ($_GET as $getname => $getvalue) {
                $getheaders[$getname] = $getvalue;
            }
            return $getheaders;
      }

      #$_POST headers
      function getallpostheaders() {
        if (!is_array($_POST)) {
            return array();
        }
        $postheaders = array();
        foreach ($_POST as $postname => $postvalue) {
                $postheaders[$postname] = $postvalue;
            }
            return $postheaders;
      }

      #$_REQUEST headers
      function getallrequestheaders() {
        if (!is_array($_REQUEST)) {
            return array();
        }
        $requestheaders = array();
        foreach ($_REQUEST as $requestname => $requestvalue) {
                $requestheaders[$requestname] = $requestvalue;
            }
            return $requestheaders;
      }

      #$_SESSION headers
      function getallsessionheaders() {
        if (!is_array($_SESSION)) {
            return array();
        }
        $sessionheaders = array();
        foreach ($_SESSION as $sessionname => $sessionvalue) {
                $sessionheaders[$sessionname] = $sessionvalue;
            }
            return $sessionheaders;
      }

      #$_ENV headers
      function getallenvheaders() {
        if (!is_array($_ENV)) {
            return array();
        }
        $envheaders = array();
        foreach ($_ENV as $envname => $envvalue) {
                $envheaders[$envname] = $envvalue;
            }
            return $envheaders;
      }

      #$_COOKIE headers
      function getallcookieheaders() {
        if (!is_array($_COOKIE)) {
            return array();
        }
        $cookieheaders = array();
        foreach ($_COOKIE as $cookiename => $cookievalue) {
                $cookieheaders[$cookiename] = $cookievalue;
            }
            return $cookieheaders;
      }

      #$http_response_header headers
      function getallresponseheaders() {
        $responseheaders = headers_list();
        foreach ($responseheaders as $responsename => $responsevalue) {
                $responseheaders[$responsename] = $responsevalue;
            }
            return $responseheaders;
      }


?>

</body>
</html>
