# Input
variable "name" {
  type = string
}
variable "vpc_id" {
  type = string
  default = ""
}
variable "log_bucket_name" {
  type = string
}
variable "launch_template_id" {
  type = string
}
variable "security_group_ids" {
  type = list
}
variable "subnet_ids" {
  type = list
}
variable "ssl_certificate_arn" {
  type = string
}
variable "desired_capacity" {
  type = string
}
variable "max_size" {
  type = string
}
variable "min_size" {
  type = string
}

data "aws_vpc" "default" {
  default = true
}

data "aws_vpc" "selected" {
  id = (var.vpc_id == "" ? data.aws_vpc.default.id : var.vpc_id)
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
data "aws_s3_bucket" "logs" {
  bucket = var.log_bucket_name
}

resource "aws_s3_object" "log_directory" {
  bucket = data.aws_s3_bucket.logs.id
  key    = "${var.name}/"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "main" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = true

  access_logs {
    bucket  = data.aws_s3_bucket.logs.id
    prefix  = var.name
    enabled = true
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
data "aws_availability_zones" "default" {
  all_availability_zones = true
  filter {
           name = "opt-in-status"
           values = ["opt-in-not-required"]
         }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.name}"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.selected.id
  deregistration_delay = 60

  health_check {
    protocol = "HTTPS"
    path = "/health_check"
    port = 3001
    matcher = 200
    interval = 5
    timeout = 2
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
resource "aws_autoscaling_group" "default" {
  name               = var.name
  vpc_zone_identifier = var.subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 120
  default_cooldown          = 60
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  target_group_arns  = [aws_lb_target_group.main.arn]


  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }
}

output "load_balancer_arn" {
  value = resource.aws_lb_target_group.main.arn
}
