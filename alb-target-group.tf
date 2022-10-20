resource "aws_lb_listener_rule" "green" {
  listener_arn = var.alb_listener_https_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
    forward {
      stickiness {
        duration = 0
        enabled  = false
      }
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = 100
      }
      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = 0
      }
    }
  }

  condition {
    host_header {
      values = var.hostnames
    }
  }

  lifecycle {
    ignore_changes = [
      action[0].target_group_arn,
      condition,
    ]
  }
}

resource "aws_lb_listener_rule" "blue" {
  listener_arn = var.alb_listener_https_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
    forward {
      stickiness {
        duration = 0
        enabled  = false
      }
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = 100
      }
      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = 0
      }
    }
  }

  condition {
    host_header {
      values = try(var.hostnames_blue, [])
    }
  }

  lifecycle {
    ignore_changes = [action[0].target_group_arn]
  }
}

resource "aws_lb_listener_rule" "redirects" {
  count        = length(compact(split(",", var.hostname_redirects)))
  listener_arn = var.alb_listener_https_arn

  action {
    type = "redirect"

    redirect {
      host        = var.hostnames
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = ["${element(split(",", var.hostname_redirects), count.index)}"]
    }
  }
}

resource "aws_lb_target_group" "green" {
  name                 = "ecs-${var.name}-green"
  port                 = "${var.port}"
  protocol             = "HTTP"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = 10

  health_check {
    path     = "${var.healthcheck_path}"
    interval = "${var.healthcheck_interval}"
  }
}

resource "aws_lb_target_group" "blue" {
  name                 = "ecs-${var.name}-blue"
  port                 = "${var.port}"
  protocol             = "HTTP"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = 10

  health_check {
    path     = "${var.healthcheck_path}"
    interval = "${var.healthcheck_interval}"
  }
}
