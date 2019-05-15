resource "aws_lb" "main" {
  name = "aws-nlb-lb"
  load_balancer_type = "network"
  subnets = [
    "${aws_subnet.main.id}",
  ]
}

resource "aws_lb_target_group" "main" {
  name = "aws-nlb-lb-tg"
  port = 80
  protocol = "TCP"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = "${aws_lb.main.arn}"
  port = "80"
  protocol = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.main.arn}"
    type = "forward"
  }
}
