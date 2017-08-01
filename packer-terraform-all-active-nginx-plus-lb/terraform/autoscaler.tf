# Create a Google autoscaler for the LB instance group manager
resource "google_compute_autoscaler" "lb" {
  name = "nginx-plus-lb-autoscaler"
  zone = "${var.region_zone}"
  target = "${google_compute_instance_group_manager.lb.self_link}"
  autoscaling_policy {
    max_replicas = 5
    min_replicas = 2
    cpu_utilization {
      target = 0.5
    }
  }
}

# Create a Google autoscaler for the app-1 instance group manager
resource "google_compute_autoscaler" "app-1" {
  name = "nginx-oss-app-1-autoscaler"
  zone = "${var.region_zone}"
  target = "${google_compute_instance_group_manager.app-1.self_link}"
  autoscaling_policy {
    max_replicas = 5
    min_replicas = 2
    cpu_utilization {
      target = 0.5
    }
  }
}

# Create a Google autoscaler for the app-2 instance group manager
resource "google_compute_autoscaler" "app-2" {
  name = "nginx-oss-app-2-autoscaler"
  zone = "${var.region_zone}"
  target = "${google_compute_instance_group_manager.app-2.self_link}"
  autoscaling_policy {
    max_replicas = 5
    min_replicas = 2
    cpu_utilization {
      target = 0.5
    }
  }
}
