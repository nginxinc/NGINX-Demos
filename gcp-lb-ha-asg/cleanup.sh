cd terraform \
&& yes yes | terraform destroy \
&& rm -rf .terraform terraform.* \
&& gcloud compute images delete ngx-plus ngx-oss --quiet
