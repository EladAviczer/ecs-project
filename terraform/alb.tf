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
}

resource "aws_lb_listener" "ms1_listener" {
  load_balancer_arn = aws_lb.ms1_lb.arn
  port              = "80"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ms1_tg.arn
  }
}
