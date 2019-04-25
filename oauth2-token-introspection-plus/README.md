## OAuth 2.0 Token Introspection with NGINX Plus and njs

This configuration enables NGINX Plus to validate an authentication token against an authorization server by using OAuth 2.0 Token Introspection ([RFC 7662](https://tools.ietf.org/html/rfc7662)). This solution uses the [auth_request module](http://nginx.org/en/docs/http/ngx_http_auth_request_module.html) and the [NGINX JavaScript module](http://nginx.org/en/docs/njs/index.html) to require authentication and perform the token introspection request.

By default, the client's authentication token is expected as a bearer token supplied in the `Authorization` header. If supplied elsewhere in the HTTP request, the `$access_token` variable must be configured to specify where to obtain the token.

Token introspection requests are authenticated. By default, the `$oauth_client_id` and `$oauth_client_secret` variables are used to perform HTTP Basic authentication with the Authorization Server. If only the `$oauth_client_secret` variable is specified then that value is used to perform authentication with a bearer token on the `Authorization` header.

Responses from the OAuth 2.0 authorization server are added top the in-memory [key-value store](http://nginx.org/en/docs/http/ngx_http_keyval_module.html) to minimize latency on each request. Stored responses will be sycnhronized across a cluster of NGINX Plus instances if [runtime state sharing](https://docs.nginx.com/nginx/admin-guide/high-availability/zone_sync/) has been enabled.

If the introspection response contains member data then each member can be accessed as NGINX variables by using `auth_request_set $new_variable $sent_http_token_membername;`. Such variables can then be logged, used for conditional access control, and proxied upstream to provide identity metadata to the backend application.

The token introspection result is logged to the error log. Change the `error_log` severity level to affect verbosity.
