# Create a Google autoscaler for the load balancer instance group manager
resource "google_compute_autoscaler" "lb" {
  name   = "ngx-plus-lb-autoscaler"
  zone   = var.region_zone
  target = google_compute_instance_group_manager.lb.self_link
  autoscaling_policy {
    max_replicas = 5
    min_replicas = 2
    cpu_utilization {
      target = 0.5
    }
  }
}

# Create a Google autoscaler for the app one instance group manager
resource "google_compute_autoscaler" "app_one" {
  name   = "ngx-oss-app-one-autoscaler"
  zone   = var.region_zone
  target = google_compute_instance_group_manager.app_one.self_link
  autoscaling_policy {
    max_replicas = 5
    min_replicas = 2
    cpu_utilization {
      target = 0.5
    }
  }
}

# Create a Google autoscaler for the app two instance group manager
resource "google_compute_autoscaler" "app_two" {
  name   = "ngx-oss-app-two-autoscaler"
  zone   = var.region_zone
  target = google_compute_instance_group_manager.app_two.self_link
  autoscaling_policy {
    max_replicas = 5
    min_replicas = 2
    cpu_utilization {
      target = 0.5
    }
  }
}
