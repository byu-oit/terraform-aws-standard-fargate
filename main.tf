terraform {
  required_version = ">= 0.12.21"
  required_providers {
    aws = ">= 2.51"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  assummed_tags = {
    env              = var.env
    data-sensitivity = "confidential"
  }
  tags                   = merge(local.assummed_tags, var.tags)
  has_secrets            = length(var.container_secrets) > 0
  ssm_parameter_arn_base = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/"

  secrets_arns = [
    for key in keys(var.container_secrets) :
    "${local.ssm_parameter_arn_base}${replace(lookup(var.container_secrets, key), "/^//", "")}"
  ]

  alb_name = "${var.app_name}-alb" // ALB name has a restriction of 32 characters max
  app_domain_url = "${var.app_name}.${var.hosted_zone.name}" // Route53 A record name
}

# ==================== ALB ====================
resource "aws_alb" "alb" {
  name = local.alb_name
  subnets = var.public_subnet_ids
  security_groups = [aws_security_group.alb-sg.id]
  tags = var.tags
}
resource "aws_security_group" "alb-sg" {
  name        = "${local.alb_name}-sg"
  description = "Controls access to the ${local.alb_name}"
  vpc_id      = var.vpc_id

  // allow access to the ALB from anywhere for 80 and 443
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  // allow any outgoing traffic
  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}
resource "aws_alb_target_group" "blue" {
  name     = "${var.app_name}-tgb"
  port     = var.image_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type          = "ip"
  deregistration_delay = var.target_group_deregistration_delay
  health_check {
    path                = var.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = var.tags

  depends_on = [aws_alb.alb]
}
resource "aws_alb_target_group" "green" {
  name     = "${var.app_name}-tgg"
  port     = var.image_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type          = "ip"
  deregistration_delay = var.target_group_deregistration_delay
  health_check {
    path                = var.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = var.tags

  depends_on = [aws_alb.alb]
}
resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.alb.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = var.https_certificate_arn
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.blue.arn
  }
  lifecycle {
    ignore_changes = [default_action[0].target_group_arn]
  }
}
resource "aws_alb_listener" "http_to_https" {
  load_balancer_arn = aws_alb.alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      port = aws_alb_listener.https.port
      protocol = aws_alb_listener.https.protocol
    }
  }
}
// TODO add test listener if requested in a variable of some kind?

# ==================== Route53 ====================
resource "aws_route53_record" "a_record" {
  name    = local.app_domain_url
  type    = "A"
  zone_id = var.hosted_zone.id
  alias {
    evaluate_target_health = true
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
  }
}
resource "aws_route53_record" "aaaa_record" {
  name    = local.app_domain_url
  type    = "AAAA"
  zone_id = var.hosted_zone.id
  alias {
    evaluate_target_health = true
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
  }
}

# ==================== Fargate ====================

// Make sure the fargate task has access to get the parameters from the container secrets
//data "aws_iam_policy_document" "secrets_access" {
//  count = local.has_secrets ? 1 : 0
//
//  version = "2012-10-17"
//  statement {
//    effect = "Allow"
//    actions = [
//      "ssm:GetParameters",
//      "ssm:GetParameter",
//      "ssm:GetParemetersByPath"
//    ]
//    resources = local.secrets_arns
//  }
//}
//resource "aws_iam_policy" "secrets_access" {
//  count = local.has_secrets ? 1 : 0
//
//  name   = "${var.app_name}_secrets_access"
//  policy = data.aws_iam_policy_document.secrets_access[0].json
//}
//
//module "fargate" {
//  //  source              = "../terraform-aws-fargate"
//  source              = "github.com/byu-oit/terraform-aws-fargate?ref=v1.2.3"
//  app_name            = var.app_name
//  vpc_id              = module.acs.vpc.id
//  subnet_ids          = module.acs.private_subnet_ids
//  load_balancer_sg_id = module.alb.alb_security_group.id
//  security_groups     = var.security_groups
//  target_groups = [
//    {
//      arn  = module.alb.target_groups["blue"].arn
//      port = module.alb.target_groups["blue"].port
//    }
//  ]
//  task_cpu                = var.task_cpu
//  task_memory             = var.task_memory
//  container_image         = var.container_image_url
//  container_env_variables = var.container_env_variables
//  container_secrets       = var.container_secrets
//  task_policies           = concat(length(aws_iam_policy.secrets_access) > 0 ? [aws_iam_policy.secrets_access[0].arn] : [], var.task_policies)
//  task_execution_policies = length(aws_iam_policy.secrets_access) > 0 ? [aws_iam_policy.secrets_access[0].arn] : []
//  blue_green_deployment_config = {
//    termination_wait_time_after_deployment_success = null // defaults to 15
//    prod_traffic_listener_arns                     = [module.alb.listeners[443].arn]
//    test_traffic_listener_arns                     = []
//    //Note: The `lookup` is used because there have been cases where it can't find the map value when trying to destroy
//    //and that caused the destroy to fail
//    blue_target_group_name  = lookup(module.alb.target_groups, "blue", null) != null ? module.alb.target_groups["blue"].name : null
//    green_target_group_name = lookup(module.alb.target_groups, "green", null) != null ? module.alb.target_groups["green"].name : null
//    service_role_arn        = module.acs.power_builder_role.arn
//  }
//
//  module_depends_on             = [module.alb.alb]
//  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn
//  log_retention_in_days         = var.log_retention_in_days
//  health_check_grace_period     = var.health_check_grace_period
//  tags                          = local.tags
//}
//
//module "autoscaling" {
//  source             = "github.com/byu-oit/terraform-aws-app-autoscaling?ref=v1.0.1"
//  app_name           = var.app_name
//  min_capacity       = var.min_capacity
//  max_capacity       = var.max_capacity
//  resource_id        = "service/${module.fargate.ecs_cluster.name}/${module.fargate.ecs_service.name}"
//  scalable_dimension = "ecs:service:DesiredCount"
//  service_namespace  = "ecs"
//  step_up = {
//    adjustment_type         = "ChangeInCapacity"
//    cooldown                = 300
//    metric_aggregation_type = null // use default
//    step_adjustments = [
//      {
//        lower_bound        = 0
//        upper_bound        = null
//        scaling_adjustment = 1
//      }
//    ]
//
//    alarm = {
//      namespace = "AWS/ECS"
//      dimensions = {
//        ClusterName = module.fargate.ecs_cluster.name
//        ServiceName = module.fargate.ecs_service.name
//      }
//      statistic           = null // use default
//      metric_name         = "CPUUtilization"
//      comparison_operator = "GreaterThanThreshold"
//      threshold           = 75
//      period              = null // use default
//      evaluation_periods  = null // use default
//    }
//  }
//
//  step_down = {
//    adjustment_type         = "ChangeInCapacity"
//    cooldown                = 300
//    metric_aggregation_type = null // use default
//    step_adjustments = [
//      {
//        lower_bound        = null
//        upper_bound        = 0
//        scaling_adjustment = -1
//      }
//    ]
//
//    alarm = {
//      namespace = "AWS/ECS"
//      dimensions = {
//        ClusterName = module.fargate.ecs_cluster.name
//        ServiceName = module.fargate.ecs_service.name
//      }
//      statistic           = null // use default
//      metric_name         = "CPUUtilization"
//      comparison_operator = "LessThanThreshold"
//      threshold           = 25
//      period              = null // use default
//      evaluation_periods  = null // use default
//    }
//  }
//
//  tags = local.tags
//}

