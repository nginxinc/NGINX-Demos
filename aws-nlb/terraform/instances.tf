resource "aws_instance" "ngx-plus-1" {
  ami = "${data.aws_ami.ngx-plus.id}"
  instance_type = "${var.machine_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  subnet_id = "${aws_subnet.main.id}"
  user_data = "${data.template_file.ngx-plus.rendered}"
  tags {
    Name = "ngx-plus-1",
  }
}

resource "aws_instance" "ngx-plus-2" {
  ami = "${data.aws_ami.ngx-plus.id}"
  instance_type = "${var.machine_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  subnet_id = "${aws_subnet.main.id}"
  user_data = "${data.template_file.ngx-plus.rendered}"
  tags {
    Name = "ngx-plus-2",
  }
}

resource "aws_instance" "ngx-oss-app1-1" {
  ami = "${data.aws_ami.ngx-oss.id}"
  instance_type = "${var.machine_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  subnet_id = "${aws_subnet.main.id}"
  user_data = "${data.template_file.ngx-oss-app1.rendered}"
  tags {
    Name = "ngx-oss-app1-1",
  }
}

resource "aws_instance" "ngx-oss-app1-2" {
  ami = "${data.aws_ami.ngx-oss.id}"
  instance_type = "${var.machine_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  subnet_id = "${aws_subnet.main.id}"
  user_data = "${data.template_file.ngx-oss-app1.rendered}"
  tags {
    Name = "ngx-oss-app1-2",
  }
}

resource "aws_instance" "ngx-oss-app2-1" {
  ami = "${data.aws_ami.ngx-oss.id}"
  instance_type = "${var.machine_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  subnet_id = "${aws_subnet.main.id}"
  user_data = "${data.template_file.ngx-oss-app2.rendered}"
  tags {
    Name = "ngx-oss-app2-1",
  }
}

resource "aws_instance" "ngx-oss-app2-2" {
  ami = "${data.aws_ami.ngx-oss.id}"
  instance_type = "${var.machine_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  subnet_id = "${aws_subnet.main.id}"
  user_data = "${data.template_file.ngx-oss-app2.rendered}"
  tags {
    Name = "ngx-oss-app2-2",
  }
}
