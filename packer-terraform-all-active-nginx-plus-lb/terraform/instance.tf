# Create a Google compute instance template for the NGINX LB
resource "google_compute_instance_template" "lb" {
  name = "nginx-plus-lb-instance-template"
  description = "NGINX Plus Load Balancing Instance Template"
  machine_type = "${var.machine_type}"
  tags = [
    "nginx-http-fw-rule",
  ]
  disk {
    source_image = "nginx-plus-lb-image"
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute",
    ]
  }
  metadata {
    startup-script = <<EOF
appip=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --regexp=.*app.*)
arrapp=($appip)
for (( i=0; i < $${#arrapp[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://localhost/upstream_conf?upstream=upstream_app_pool' | grep -Eo 'server ([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
  upstrarr=($upstrlist)
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    if [ "$${arrapp[i]}" = "$${upstrarr[j]}" ]; then
      is_present=true;
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -s 'http://localhost/upstream_conf?add=&upstream=upstream_app_pool&server='"$${arrapp[i]}"'';
  fi;
done;
EOF
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create a Google compute instance template for the NGINX app-1
resource "google_compute_instance_template" "app-1" {
  name = "nginx-oss-app-1-instance-template"
  description = "NGINX OSS app-1 Instance Template"
  machine_type = "${var.machine_type}"
  tags = [
    "nginx-http-fw-rule",
  ]
  disk {
    source_image = "nginx-oss-app-1-image"
  }
  network_interface {
    network = "default"
  }
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute",
    ]
  }
  metadata {
    startup-script = <<EOF
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
lbip=$(gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --regexp=.*lb.*)
arrlb=($lbip)
for (( i=0; i < $${#arrlb[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://'"$${arrlb[i]}"'/upstream_conf?upstream=upstream_app_pool' | grep -Eo 'server ([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
  upstrarr=($upstrlist)
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    if [ "$inip" = "$${upstrarr[j]}" ]; then
      is_present=true;
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -s 'http://'"$${arrlb[i]}"'/upstream_conf?add=&upstream=upstream_app_pool&server='"$inip"'';
  else
    echo "Already present";
  fi;
done;
EOF
    shutdown-script = <<EOF
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --regexp=.*lb.* | while read -r lb; do
  for ID in $(curl -s 'http://'"$lb"'/upstream_conf?upstream=upstream_app_pool' | grep -o 'server '"$inip"':80; # id=[0-9]\+' | grep -o 'id=[0-9]\+' | grep -o '[0-9]\+'); do
    curl 'http://'"$lb"'/upstream_conf?remove=&upstream=upstream_app_pool&id='"$ID"'';
  done;
done;
EOF
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create a Google compute instance template for the NGINX app-2
resource "google_compute_instance_template" "app-2" {
  name = "nginx-oss-app-2-instance-template"
  description = "NGINX OSS app-2 Instance Template"
  machine_type = "${var.machine_type}"
  tags = [
    "nginx-http-fw-rule",
  ]
  disk {
    source_image = "nginx-oss-app-2-image"
  }
  network_interface {
    network = "default"
  }
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute",
    ]
  }
  metadata {
    startup-script = <<EOF
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
lbip=$(gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --regexp=.*lb.*)
arrlb=($lbip)
for (( i=0; i < $${#arrlb[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://'"$${arrlb[i]}"'/upstream_conf?upstream=upstream_app_pool' | grep -Eo 'server ([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
  upstrarr=($upstrlist)
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    if [ "$inip" = "$${upstrarr[j]}" ]; then
      is_present=true;
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -s 'http://'"$${arrlb[i]}"'/upstream_conf?add=&upstream=upstream_app_pool&server='"$inip"'';
  else
    echo "Already present";
  fi;
done;
EOF
    shutdown-script = <<EOF
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --regexp=.*lb.* | while read -r lb; do
  for ID in $(curl -s 'http://'"$lb"'/upstream_conf?upstream=upstream_app_pool' | grep -o 'server '"$inip"':80; # id=[0-9]\+' | grep -o 'id=[0-9]\+' | grep -o '[0-9]\+'); do
    curl 'http://'"$lb"'/upstream_conf?remove=&upstream=upstream_app_pool&id='"$ID"'';
  done;
done;
EOF
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Configure a Google compute instance group manager for the NGINX LB
resource "google_compute_instance_group_manager" "lb" {
  name = "nginx-plus-lb-instance-group"
  description = "Instance group to host NGINX Plus load balancing instances"
  base_instance_name = "nginx-plus-lb-instance-group"
  instance_template = "${google_compute_instance_template.lb.self_link}"
  zone = "${var.region_zone}"
  target_pools = [
    "${google_compute_target_pool.default.self_link}",
  ]
  target_size = 2
  provisioner "local-exec" {
    command = "gcloud config set project ${var.project_id}"
  }
  provisioner "local-exec" {
    command = "gcloud beta compute instance-groups managed set-autohealing ${google_compute_instance_group_manager.lb.id} --initial-delay=300 --http-health-check=${google_compute_http_health_check.default.id} --zone=${var.region_zone}"
  }
}

# Configure a Google compute instance group manager for the NGINX app-1
resource "google_compute_instance_group_manager" "app-1" {
  name = "nginx-oss-app-1-instance-group"
  description = "Instance group to host NGINX OSS app-1 instances"
  base_instance_name = "nginx-oss-app-1-instance-group"
  instance_template = "${google_compute_instance_template.app-1.self_link}"
  zone = "${var.region_zone}"
  target_size = 2
  provisioner "local-exec" {
    command = "gcloud config set project ${var.project_id}"
  }
  provisioner "local-exec" {
    command = "gcloud beta compute instance-groups managed set-autohealing ${google_compute_instance_group_manager.app-1.id} --initial-delay=300 --http-health-check=${google_compute_http_health_check.default.id} --zone=${var.region_zone}"
  }
}

# Configure a Google compute instance group manager for the NGINX app-2
resource "google_compute_instance_group_manager" "app-2" {
  name = "nginx-oss-app-2-instance-group"
  description = "Instance group to host NGINX OSS app-2 instances"
  base_instance_name = "nginx-oss-app-2-instance-group"
  instance_template = "${google_compute_instance_template.app-2.self_link}"
  zone = "${var.region_zone}"
  target_size = 2
  provisioner "local-exec" {
    command = "gcloud config set project ${var.project_id}"
  }
  provisioner "local-exec" {
    command = "gcloud beta compute instance-groups managed set-autohealing ${google_compute_instance_group_manager.app-2.id} --initial-delay=300 --http-health-check=${google_compute_http_health_check.default.id} --zone=${var.region_zone}"
  }
}
