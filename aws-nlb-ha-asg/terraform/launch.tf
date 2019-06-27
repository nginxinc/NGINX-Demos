# Create launch configuration for NGINX Plus instances
resource "aws_launch_configuration" "ngx_plus" {
  name          = "ngx-plus"
  image_id      = data.aws_ami.ngx_plus.id
  instance_type = var.machine_type
  key_name      = var.key_name
  security_groups = [
    aws_security_group.main.id,
  ]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.main.name
}

# Create launch configuration for NGINX Open Source app 1 instances
resource "aws_launch_configuration" "ngx_oss_one" {
  name          = "ngx-oss-one"
  image_id      = data.aws_ami.ngx_oss.id
  instance_type = var.machine_type
  key_name      = var.key_name
  security_groups = [
    aws_security_group.main.id,
  ]
  associate_public_ip_address = true
}

# Create launch configuration for NGINX Open Source app 2 instances
resource "aws_launch_configuration" "ngx_oss_two" {
  name          = "ngx-oss-two"
  image_id      = data.aws_ami.ngx_oss.id
  instance_type = var.machine_type
  key_name      = var.key_name
  security_groups = [
    aws_security_group.main.id,
  ]
  associate_public_ip_address = true
}
