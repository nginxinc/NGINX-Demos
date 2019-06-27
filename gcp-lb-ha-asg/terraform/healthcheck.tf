# Configure HTTP Health Checks for NGINX
resource "google_compute_http_health_check" "default" {
  name                = "ngx-http-health-check"
  description         = "Basic HTTP health check to monitor NGINX instances"
  request_path        = "/"
  check_interval_sec  = 10
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 10
}
