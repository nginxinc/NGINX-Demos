# Create a Google compute instance template for the NGINX Plus load balancer
resource "google_compute_instance_template" "lb" {
  name         = "ngx-plus-lb-instance-template"
  description  = "NGINX Plus load balancer instance template"
  machine_type = var.machine_type
  tags = [
    "nginx-http-fw-rule",
  ]
  disk {
    source_image = "ngx-plus"
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
  metadata = {
    startup-script = <<EOF
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
appip=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name~'.*app-one.*'")
arrapp=($appip)
for (( i=0; i < $${#arrapp[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://localhost:8080/api/4/http/upstreams/app_one/servers' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
  upstrarr=($upstrlist)
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    if [ "$${arrapp[i]}" = "$${upstrarr[j]}" ]; then
      is_present=true;
      echo "Server $${arrapp[i]} is already contained in the $inip upstream group"
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -X POST -d '{"server": "'"$${arrapp[i]}"'"}' -s 'http://localhost:8080/api/4/http/upstreams/app_one/servers';
    echo "Server $${arrapp[i]} has been added to the $inip upstream group"
  fi;
done;
appip=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name~'.*app-two.*'")
arrapp=($appip)
for (( i=0; i < $${#arrapp[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://localhost:8080/api/4/http/upstreams/app_two/servers' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
  upstrarr=($upstrlist)
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    if [ "$${arrapp[i]}" = "$${upstrarr[j]}" ]; then
      is_present=true;
      echo "Server $${arrapp[i]} is already contained in the $inip upstream group"
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -X POST -d '{"server": "'"$${arrapp[i]}"'"}' -s 'http://localhost:8080/api/4/http/upstreams/app_two/servers';
    echo "Server $${arrapp[i]} has been added to the $inip upstream group"
  fi;
done;
EOF

  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create a Google compute instance template for the NGINX app one
resource "google_compute_instance_template" "app_one" {
  name = "ngx-oss-app-one-instance-template"
  description = "Open source NGINX app one instance template"
  machine_type = var.machine_type
  tags = [
    "ngx-http-fw-rule",
  ]
  disk {
    source_image = "ngx-oss"
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
  metadata = {
    startup-script = <<EOF
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
lbip=$(gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --filter="name~'.*lb.*'")
arrlb=($lbip)
for (( i=0; i < $${#arrlb[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://'"$${arrlb[i]}"':8080/api/4/http/upstreams/app_one/servers' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
  upstrarr=($upstrlist)
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    if [ "$inip" = "$${upstrarr[j]}" ]; then
      is_present=true;
      echo "Server $inip is already contained in the $${arrlb[i]} upstream group"
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -X POST -d '{"server": "'"$inip"'"}' -s 'http://'"$${arrlb[i]}"':8080/api/4/http/upstreams/app_one/servers';
    echo "Server $inip has been added to the $${arrlb[i]} upstream group"
  fi;
done;
EOF

shutdown-script = <<EOF
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --filter="name~'.*lb.*'" | while read -r lb; do
  for ID in $(curl -s 'http://'"$lb"':8080/api/4/http/upstreams/app_one/servers' | grep -o '"id":[0-9]\+,"server":"'"$inip"':80"' | grep -o '"id":[0-9]\+' | grep -o '[0-9]\+'); do
    curl -X DELETE -s 'http://'"$lb"':8080/api/4/http/upstreams/app_one/servers/'"$ID"'';
    echo "Server $inip has been removed from the $lb upstream group"
  done;
done;
EOF

}
lifecycle {
create_before_destroy = true
}
}

# Create a Google compute instance template for the NGINX app two
resource "google_compute_instance_template" "app_two" {
name = "ngx-oss-app-two-instance-template"
description = "Open source NGINX app two instance template"
machine_type = var.machine_type
tags = [
"ngx-http-fw-rule",
]
disk {
source_image = "ngx-oss"
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
metadata = {
startup-script = <<EOF
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
lbip=$(gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --filter="name~'.*lb.*'")
arrlb=($lbip)
for (( i=0; i < $${#arrlb[@]}; i++ )); do
  is_present=false;
  upstrlist=$(curl -s 'http://'"$${arrlb[i]}"':8080/api/4/http/upstreams/app_two/servers' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
  upstrarr=($upstrlist)
  for (( j=0; j < $${#upstrarr[@]}; j++ )); do
    if [ "$inip" = "$${upstrarr[j]}" ]; then
      is_present=true;
      echo "Server $inip is already contained in the $inip upstream group"
    fi;
  done;
  if [ "$is_present" = false ]; then
    curl -X POST -d '{"server": "'"$inip"'"}' -s 'http://'"$${arrlb[i]}"':8080/api/4/http/upstreams/app_two/servers';
    echo "Server $inip has been added to the $${arrlb[i]} upstream group"
  fi;
done;
EOF

    shutdown-script = <<EOF
inip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1');
gcloud compute instances list --format="value(networkInterfaces[0].accessConfigs[0].natIP)" --filter="name~'.*lb.*'" | while read -r lb; do
  for ID in $(curl -s 'http://'"$lb"':8080/api/4/http/upstreams/app_two/servers' | grep -o '"id":[0-9]\+,"server":"'"$inip"':80"' | grep -o '"id":[0-9]\+' | grep -o '[0-9]\+'); do
    curl -X DELETE -s 'http://'"$lb"':8080/api/4/http/upstreams/app_two/servers/'"$ID"'';
    echo "Server $inip has been removed from the $lb upstream group"
  done;
done;
EOF

  }
  lifecycle {
    create_before_destroy = true
  }
}

# Configure a Google compute instance group manager for the NGINX Plus load balancer
resource "google_compute_instance_group_manager" "lb" {
  provider = google-beta
  name = "ngx-plus-lb-instance-group"
  description = "Instance group to host NGINX Plus load balancing instances"
  base_instance_name = "nginx-plus-lb-instance-group"
  version {
    name = "ngx-plus-lb-instance-group"
    instance_template = google_compute_instance_template.lb.self_link
  }
  zone = var.region_zone
  target_pools = [
    google_compute_target_pool.default.self_link,
  ]
  auto_healing_policies {
    health_check = google_compute_http_health_check.default.self_link
    initial_delay_sec = 300
  }
}

# Configure a Google compute instance group manager for the NGINX app 1
resource "google_compute_instance_group_manager" "app_one" {
  provider = google-beta
  name = "ngx-oss-app-one-instance-group"
  description = "Instance group to host open source NGINX app one instances"
  base_instance_name = "nginx-oss-app-one-instance-group"
  version {
    name = "ngx-oss-app-one-instance-group"
    instance_template = google_compute_instance_template.app_one.self_link
  }
  zone = var.region_zone
  auto_healing_policies {
    health_check = google_compute_http_health_check.default.self_link
    initial_delay_sec = 300
  }
}

# Configure a Google compute instance group manager for the NGINX app 2
resource "google_compute_instance_group_manager" "app_two" {
  provider = google-beta
  name = "ngx-oss-app-two-instance-group"
  description = "Instance group to host open source NGINX app two instances"
  base_instance_name = "nginx-oss-app-two-instance-group"
  version {
    name = "ngx-oss-app-two-instance-group"
    instance_template = google_compute_instance_template.app_two.self_link
  }
  zone = var.region_zone
  auto_healing_policies {
    health_check = google_compute_http_health_check.default.self_link
    initial_delay_sec = 300
  }
}
