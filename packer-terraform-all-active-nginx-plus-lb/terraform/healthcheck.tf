# Configure HTTP Health Checks for Nginx
resource "google_compute_http_health_check" "default" {
  name = "nginx-plus-http-health-check"
  description = "Basic HTTP health check to monitor NGINX Plus instances"
  request_path = "/"
  check_interval_sec = 10
  timeout_sec = 10
  healthy_threshold = 2
  unhealthy_threshold = 10
}
