variable "project_id" {
  description = "The ID of the Google Cloud project"
  default = "all-active-nginx-plus-lb"
}

variable "region" {
  description = "The region in which to deploy the Google Cloud project"
  default = "us-west1"
}

variable "region_zone" {
  description = "The region zone in which to deploy the Google Cloud project"
  default = "us-west1-a"
}

variable "machine_type" {
  description = "The type of machine used to deploy NGINX"
  default = "n1-standard-1"
}

variable "credentials_file_path" {
  description = "Path to the JSON file used to describe your account credentials"
  default = "~/.gcloud/gcloud_credentials.json"
}
