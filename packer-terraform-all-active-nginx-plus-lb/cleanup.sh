cd terraform && yes yes | terraform destroy && rm -rf .terraform && gcloud compute images delete ngx-plus-lb ngx-oss-app-1 ngx-oss-app-2 --quiet
