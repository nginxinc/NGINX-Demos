resource "aws_autoscaling_group" "ngx-plus" {
  name = "ngx-plus-autoscaling"
  min_size = 2
  max_size = 10
  launch_configuration = "${aws_launch_configuration.ngx-plus.name}"
  vpc_zone_identifier = [
    "${aws_subnet.main.id}",
  ]
  tags = [
    {
      key = "Name",
      value = "ngx-plus",
      propagate_at_launch = true,
    },
    {
      key = "Timestamp",
      value = "${timestamp()}",
      propagate_at_launch = true,
    },
  ]
  target_group_arns = [
    "${aws_lb_target_group.main.arn}",
  ]
}

resource "aws_autoscaling_group" "ngx-oss-1" {
  name = "ngx-oss-1-autoscaling"
  min_size = 2
  max_size = 10
  launch_configuration = "${aws_launch_configuration.ngx-oss-1.name}"
  vpc_zone_identifier = [
    "${aws_subnet.main.id}",
  ]
  tags = [
    {
      key = "Name",
      value = "ngx-oss-1",
      propagate_at_launch = true,
    },
    {
      key = "Timestamp",
      value = "${timestamp()}",
      propagate_at_launch = true,
    },
  ]
}

resource "aws_autoscaling_group" "ngx-oss-2" {
  name = "ngx-oss-2-autoscaling"
  min_size = 2
  max_size = 10
  launch_configuration = "${aws_launch_configuration.ngx-oss-2.name}"
  vpc_zone_identifier = [
    "${aws_subnet.main.id}",
  ]
  tags = [
    {
      key = "Name",
      value = "ngx-oss-2",
      propagate_at_launch = true,
    },
    {
      key = "Timestamp",
      value = "${timestamp()}",
      propagate_at_launch = true,
    },
  ]
}
