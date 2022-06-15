
resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.env}-Backend-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_main_id

  health_check {
    path                = "/docs"
    protocol            = "HTTP"
    matcher             = "401"
    interval            = 300
    timeout             = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "frontend_tg" {
  name     = "${var.env}-Frontend-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_main_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 300
    timeout             = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

locals {
  pub_subnets = data.aws_subnet.pub_subnet
}

resource "aws_lb" "frontend" {
  name               = "${var.env}-${var.facing_lb_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = [for subnet in var.pub_subnet_ids : subnet.id]

  tags = {
    Environment      = var.env
    AmazonECSManaged = true
  }
  # depends_on = [aws_autoscaling_group.ecs_asg]
}

resource "aws_lb_listener" "frontend_http_alb" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "app_https_alb" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_cert_validation_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }


}

resource "aws_lb_listener_rule" "backend_page" {
  listener_arn = aws_lb_listener.app_https_alb.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    host_header {
      values = ["${var.env}-api.${var.domain_name}"]
    }
  }
}
