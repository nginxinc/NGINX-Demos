output "nlb_dns" {
  description = "This is the DNS name of the NGINX environment"
  value = "${aws_lb.main.dns_name}"
}
