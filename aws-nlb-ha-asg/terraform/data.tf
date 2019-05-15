data "aws_ami" "ngx-plus" {
  most_recent = true
  filter {
    name   = "tag:Name"
    values = [
      "ngx-plus"
    ]
  }
}

data "aws_ami" "ngx-oss" {
  most_recent = true
  filter {
    name   = "tag:Name"
    values = [
      "ngx-oss"
    ]
  }
}
