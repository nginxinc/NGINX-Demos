resource "aws_launch_configuration" "ngx-plus" {
  name = "ngx-plus"
  image_id = "${data.aws_ami.ngx-plus.id}"
  instance_type = "${var.machine_type}"
  key_name = "${var.key_name}"
  security_groups = [
    "${aws_security_group.main.id}",
  ]
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.main.name}"
}

resource "aws_launch_configuration" "ngx-oss-1" {
  name = "ngx-oss-1"
  image_id = "${data.aws_ami.ngx-oss.id}"
  instance_type = "${var.machine_type}"
  key_name = "${var.key_name}"
  security_groups = [
    "${aws_security_group.main.id}",
  ]
  associate_public_ip_address = true
}

resource "aws_launch_configuration" "ngx-oss-2" {
  name = "ngx-oss-2"
  image_id = "${data.aws_ami.ngx-oss.id}"
  instance_type = "${var.machine_type}"
  key_name = "${var.key_name}"
  security_groups = [
    "${aws_security_group.main.id}",
  ]
  associate_public_ip_address = true
}
