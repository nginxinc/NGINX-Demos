output "static_external_ip" {
  description = "This is the static external IP of the Nginx environment"
  value = "${google_compute_address.default.address}"
}
