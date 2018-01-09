<?php
/******************************************************************************
 * httpGet
 ******************************************************************************/
function httpGet($url) {

    $responseCode = 0;
    $responseData = '';
    $error = '';

    $ch = curl_init();

    try {
        curl_setopt($ch, CURLOPT_URL, str_replace(' ', '%20', $url));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        // Send request
        $response = curl_exec($ch);

        if (curl_errno($ch)) {
            $error = "Curl error: [" . curl_errno($ch) . "] $curl_error($ch)";
        } else {
            $responseInfo = curl_getinfo($ch);
            if (isset($responseInfo['http_code'])) {
                $responseCode = $responseInfo['http_code'];
                $responseData = $response;
             } else {
                $error = "Error: HTTP response code not set";
             }
        }
    } catch (Exception $e) {
        $curlError = curl_error($ch);
        if (isset($responseInfo['http_code'])) {
            $httpCode = $responseInfo['http_code'];
        }
        $error = "Curl Exception: url=$errorURL  responseCode=$httpCode  Curl Error=$curlError";
    }

    curl_close($ch);

    $responseArray = array("ResponseCode" => $responseCode, "ResponseData" => $responseData, "Error" => $error);

    return $responseArray;
}
?>
