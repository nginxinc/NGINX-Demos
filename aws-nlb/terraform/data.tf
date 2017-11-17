data "template_file" "ngx-plus" {
  template = "${file("scripts/setup-lb.tpl")}"
  vars {
    ngx-oss-app1-1-ip = "${aws_instance.ngx-oss-app1-1.private_ip}"
    ngx-oss-app1-2-ip = "${aws_instance.ngx-oss-app1-2.private_ip}"
    ngx-oss-app2-1-ip = "${aws_instance.ngx-oss-app2-1.private_ip}"
    ngx-oss-app2-2-ip = "${aws_instance.ngx-oss-app2-2.private_ip}"
  }
}

data "template_file" "ngx-oss-app1" {
  template = "${file("scripts/setup-app.tpl")}"
  vars {
    app-number = "1"
  }
}

data "template_file" "ngx-oss-app2" {
  template = "${file("scripts/setup-app.tpl")}"
  vars {
    app-number = "2"
  }
}

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
