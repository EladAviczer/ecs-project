resource "aws_lb" "ms1_lb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "ms1_tg" {
  name        = "ms1-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 10 # Very high threshold
    timeout             = 2
    interval            = 30
    protocol            = "HTTP"
    port                = "80"
    path                = "/submit"
    matcher             = "200-499" # Accept almost any HTTP response (not 5xx server errors)
  }

}

resource "aws_lb_listener" "ms1_listener" {
  load_balancer_arn = aws_lb.ms1_lb.arn
  port              = "80"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ms1_tg.arn
  }
}


resource "aws_lb_listener_rule" "submit_rule" {
  listener_arn = aws_lb_listener.ms1_listener.arn
  priority     = 10 # must be unique and lower = higher priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ms1_tg.arn
  }

  condition {
    path_pattern {
      values = ["/submit"]
    }
  }
}
