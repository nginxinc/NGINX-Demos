cd terraform && yes yes | terraform destroy && rm -rf .terraform && gcloud compute images delete nginx-plus-lb-image nginx-oss-app-1-image nginx-oss-app-2-image --quiet
