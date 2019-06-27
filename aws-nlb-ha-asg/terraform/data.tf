# Fetch AWS NGINX Plus AMI identifiers
data "aws_ami" "ngx_plus" {
  most_recent = true
  owners      = ["self"]
  filter {
    name = "tag:Name"
    values = [
      "ngx-plus",
    ]
  }
}

# Fetch AWS NGINX Open Source AMI identifiers
data "aws_ami" "ngx_oss" {
  most_recent = true
  owners      = ["self"]
  filter {
    name = "tag:Name"
    values = [
      "ngx-oss",
    ]
  }
}
