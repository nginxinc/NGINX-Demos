# Create a Google compute instance template for the NGINX LB
resource "google_compute_instance_template" "lb" {
  name = "ngx-plus-lb-instance-template"
  description = "NGINX Plus load balancer instance template"
  machine_type = "${var.machine_type}"
  tags = [
    "nginx-http-fw-rule",
  ]
  disk {
    source_image = "ngx-plus-lb"
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
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
appip=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name~'.*app.*'")
arrapp=($appip)
for (( i=0; i < $${#arrapp[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://localhost:8080/api/3/http/upstreams/upstream_app_pool/servers' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
  upstrarr=($upstrlist)
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    if [ "$${arrapp[i]}" = "$${upstrarr[j]}" ]; then
      is_present=true;
      echo "Server $${upstrarr[j]} is already contained in the $inip upstream group"
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -X POST -d '{"server": "'"$${arrapp[i]}"'"}' -s 'http://localhost:8080/api/3/http/upstreams/upstream_app_pool/servers';
    echo "Server $${upstrarr[j]} has been added to the $inip upstream group"
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
  name = "ngx-oss-app-1-instance-template"
  description = "Open source NGINX app 1 instance template"
  machine_type = "${var.machine_type}"
  tags = [
    "nginx-http-fw-rule",
  ]
  disk {
    source_image = "ngx-oss-app-1"
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
lbip=$(gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --filter="name~'.*lb.*'")
arrlb=($lbip)
for (( i=0; i < $${#arrlb[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://'"$${arrlb[i]}"':8080/api/3/http/upstreams/upstream_app_pool/servers' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
  upstrarr=($upstrlist)
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    if [ "$inip" = "$${upstrarr[j]}" ]; then
      is_present=true;
      echo "Server $${upstrarr[j]} is already contained in the $inip upstream group"
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -X POST -d '{"server": "'"$inip"'"}' -s 'http://'"$${arrlb[i]}"':8080/api/3/http/upstreams/upstream_app_pool/servers';
    echo "Server $${upstrarr[j]} has been added to the $inip upstream group"
  fi;
done;
EOF
    shutdown-script = <<EOF
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --filter="name~'.*lb.*'"| while read -r lb; do
  for ID in $(curl -s 'http://'"$lb"':8080/api/3/http/upstreams/upstream_app_pool/servers' | grep -o '"id":[0-9]\+\','"server":"10.138.0.2:80"' | grep -o '"id":[0-9]\+' | grep -o '[0-9]\+'); do
    curl -X DELETE -s 'http://'"$lb"':8080/api/3/http/upstreams/upstream_app_pool/servers/'"$ID"'';
    echo "Server $inip has been removed from $lb upstream group"
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
  name = "ngx-oss-app-2-instance-template"
  description = "Open source NGINX app 2 instance template"
  machine_type = "${var.machine_type}"
  tags = [
    "nginx-http-fw-rule",
  ]
  disk {
    source_image = "ngx-oss-app-2"
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
lbip=$(gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --filter="name~'.*lb.*'")
arrlb=($lbip)
for (( i=0; i < $${#arrlb[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://'"$${arrlb[i]}"':8080/api/3/http/upstreams/upstream_app_pool/servers' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
  upstrarr=($upstrlist)
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    if [ "$inip" = "$${upstrarr[j]}" ]; then
      is_present=true;
      echo "Server $${upstrarr[j]} is already contained in the $inip upstream group"
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -X POST -d '{"server": "'"$inip"'"}' -s 'http://'"$${arrlb[i]}"':8080/api/3/http/upstreams/upstream_app_pool/servers';
    echo "Server $${upstrarr[j]} has been added to the $inip upstream group"
  fi;
done;
EOF
    shutdown-script = <<EOF
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --filter="name~'.*lb.*'"| while read -r lb; do
  for ID in $(curl -s 'http://'"$lb"':8080/api/3/http/upstreams/upstream_app_pool/servers' | grep -o '"id":[0-9]\+\','"server":"10.138.0.2:80"' | grep -o '"id":[0-9]\+' | grep -o '[0-9]\+'); do
    curl -X DELETE -s 'http://'"$lb"':8080/api/3/http/upstreams/upstream_app_pool/servers/'"$ID"'';
    echo "Server $inip has been removed from $lb upstream group"
  done;
done;
EOF
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Configure a Google compute instance group manager for the NGINX load balancer
resource "google_compute_instance_group_manager" "lb" {
  name = "ngx-plus-lb-instance-group"
  description = "Instance group to host NGINX Plus load balancing instances"
  base_instance_name = "nginx-plus-lb-instance-group"
  instance_template = "${google_compute_instance_template.lb.self_link}"
  zone = "${var.region_zone}"
  target_pools = [
    "${google_compute_target_pool.default.self_link}",
  ]
  target_size = 2
  auto_healing_policies {
    health_check = "${google_compute_http_health_check.default.self_link}"
    initial_delay_sec = 300
  }
}

# Configure a Google compute instance group manager for the NGINX app 1
resource "google_compute_instance_group_manager" "app-1" {
  name = "ngx-oss-app-1-instance-group"
  description = "Instance group to host open source NGINX app 1 instances"
  base_instance_name = "nginx-oss-app-1-instance-group"
  instance_template = "${google_compute_instance_template.app-1.self_link}"
  zone = "${var.region_zone}"
  target_size = 2
  auto_healing_policies {
    health_check = "${google_compute_http_health_check.default.self_link}"
    initial_delay_sec = 300
  }
}

# Configure a Google compute instance group manager for the NGINX app 2
resource "google_compute_instance_group_manager" "app-2" {
  name = "ngx-oss-app-2-instance-group"
  description = "Instance group to host open source NGINX app 2 instances"
  base_instance_name = "nginx-oss-app-2-instance-group"
  instance_template = "${google_compute_instance_template.app-2.self_link}"
  zone = "${var.region_zone}"
  target_size = 2
  auto_healing_policies {
    health_check = "${google_compute_http_health_check.default.self_link}"
    initial_delay_sec = 300
  }
}
