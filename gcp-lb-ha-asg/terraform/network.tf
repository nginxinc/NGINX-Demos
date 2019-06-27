# Configure the Google Cloud firewall
resource "google_compute_firewall" "default" {
  name        = "ngx-http-fw-rule"
  network     = "default"
  description = "Allow access to ports 80 and 8080 on all NGINX instances."
  allow {
    protocol = "tcp"
    ports = [
      "80",
      "8080",
    ]
  }
  source_ranges = [
    "0.0.0.0/0",
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]
  target_tags = [
    "nginx-http-fw-rule",
  ]
}

# Create a static IP address in Google cloud
resource "google_compute_address" "default" {
  name = "ngx-network-lb-static-ip"
}

# Create a target pool to balance incoming connections to the load balancer instance group
resource "google_compute_target_pool" "default" {
  name = "ngx-network-lb-backend"
  health_checks = [
    google_compute_http_health_check.default.name,
  ]
  session_affinity = "CLIENT_IP"
}

# Forward incoming connections to port 80 to the Google network balancer
resource "google_compute_forwarding_rule" "port_80" {
  name       = "ngx-network-lb-frontend-80"
  target     = google_compute_target_pool.default.self_link
  ip_address = google_compute_address.default.address
  port_range = "80"
}

# Forward incoming connections to port 8080 to the Google network balancer
resource "google_compute_forwarding_rule" "port_8080" {
  name       = "ngx-network-lb-frontend-8080"
  target     = google_compute_target_pool.default.self_link
  ip_address = google_compute_address.default.address
  port_range = "8080"
}
