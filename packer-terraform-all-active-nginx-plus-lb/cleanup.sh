cd terraform && yes yes | terraform destroy && rm -rf .terraform && gcloud config set project all-active-nginx-plus-lb && gcloud compute images delete ngx-plus-lb ngx-oss-app-1 ngx-oss-app-2 --quiet
