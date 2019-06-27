provider "google" {
  credentials = file(var.credentials_file_path)
  project     = var.project_id
  region      = var.region
}

provider "google-beta" {
  credentials = file(var.credentials_file_path)
  project     = var.project_id
  region      = var.region
}
