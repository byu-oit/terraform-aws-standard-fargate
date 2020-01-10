terraform {
  required_version = ">= 0.12.16"
  required_providers {
    aws = ">= 2.42"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  assummed_tags = {
    env = var.env
    data-sensitivity = "confidential"
  }
  tags = merge(local.assummed_tags, var.tags)
  has_secrets = length(var.container_secrets) > 0
  ssm_parameter_arn_base = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/"

  secrets_arns = [
  for key in keys(var.container_secrets) :
    "${local.ssm_parameter_arn_base}/${replace(lookup(var.container_secrets, key), "/^//", "")}"
  ]
}

module "acs" {
  source = "git@github.com:byu-oit/terraform-aws-acs-info.git?ref=v1.2.0"
  env    = var.env
}

module "alb" {
  source     = "git@github.com:byu-oit/terraform-aws-alb.git?ref=v1.2.0"
  name       = "${var.app_name}-alb"
  vpc_id     = module.acs.vpc.id
  subnet_ids = module.acs.public_subnet_ids
  target_groups = {
    blue = {
      port                       = var.image_port
      type                       = "ip"
      deregistration_delay       = null
      slow_start                 = null
      stickiness_cookie_duration = null
      health_check = {
        path                = var.health_check_path
        interval            = null
        timeout             = null
        healthy_threshold   = null
        unhealthy_threshold = null
      }
    },
    green = {
      port                       = var.image_port
      type                       = "ip"
      deregistration_delay       = null
      slow_start                 = null
      stickiness_cookie_duration = null
      health_check = {
        path                = var.health_check_path
        interval            = null
        timeout             = null
        healthy_threshold   = null
        unhealthy_threshold = null
      }
    }
  }
  listeners = {
    80 = {
      protocol              = "HTTP"
      https_certificate_arn = null
      redirect_to = {
        host     = null
        path     = null
        port     = 443
        protocol = "HTTPS"
      }
      forward_to = null
    },
    443 = {
      protocol              = "HTTPS"
      https_certificate_arn = module.acs.certificate.arn
      redirect_to           = null
      forward_to = {
        target_group   = "blue"
        ignore_changes = true
      }
    }
  }
  tags = local.tags
}

module "ecr" {
  source               = "git@github.com:byu-oit/terraform-aws-ecr?ref=v1.0.0"
  name                 = var.app_name
  image_tag_mutability = "IMMUTABLE"
  tags = local.tags
}

module "ecr_initial_image" {
  source             = "git@github.com:byu-oit/terraform-aws-ecr-image?ref=v1.0.0"
  dockerfile_dir     = var.dockerfile_dir
  ecr_repository_url = module.ecr.repository.repository_url
  docker_image_tag   = formatdate("YYYY-MM-DD_hh-mm", timestamp())
}

// Make sure the fargate task has access to get the parameters from the container secrets
data "aws_iam_policy_document" "secrets_access" {
  count = local.has_secrets ? 1 : 0

  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:GetParemetersByPath"
    ]
    resources = local.secrets_arns
  }
}
resource "aws_iam_policy" "secrets_access" {
  count = local.has_secrets ? 1 : 0

  name = "${var.app_name}_secrets_access"
  policy = data.aws_iam_policy_document.secrets_access[0].json
}

module "fargate" {
  source              = "git@github.com:byu-oit/terraform-aws-fargate.git?ref=v1.1.0"
  app_name            = var.app_name
  vpc_id              = module.acs.vpc.id
  subnet_ids          = module.acs.private_subnet_ids
  load_balancer_sg_id = module.alb.alb_security_group.id
  target_groups = [
    {
      arn  = module.alb.target_groups["blue"].arn
      port = module.alb.target_groups["blue"].port
    }
  ]
  container_image         = module.ecr_initial_image.ecr_image_url
  container_env_variables = var.container_env_variables
  container_secrets       = var.container_secrets
  task_policies           = local.has_secrets ? [aws_iam_policy.secrets_access[0].arn] : []

  blue_green_deployment_config = {
    termination_wait_time_after_deployment_success = null // defaults to 15
    prod_traffic_listener_arns                     = [module.alb.listeners[443].arn]
    test_traffic_listener_arns                     = []
    blue_target_group_name                         = module.alb.target_groups["blue"].name
    green_target_group_name                        = module.alb.target_groups["green"].name
    service_role_arn                               = module.acs.power_builder_role.arn
  }

  module_depends_on             = [module.alb.alb]
  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn

  tags = local.tags
}

module "autoscaling" {
  source             = "git@github.com:byu-oit/terraform-aws-app-autoscaling.git?ref=v1.0.0"
  app_name           = var.app_name
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  resource_id        = "service/${module.fargate.ecs_cluster.name}/${module.fargate.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  step_up = {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = null // use default
    step_adjustments = [
      {
        lower_bound        = 0
        upper_bound        = null
        scaling_adjustment = 1
      }
    ]

    alarm = {
      namespace = "AWS/ECS"
      dimensions = {
        ClusterName = module.fargate.ecs_cluster.name
        ServiceName = module.fargate.ecs_service.name
      }
      statistic           = null // use default
      metric_name         = "CPUUtilization"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 75
      period              = null // use default
      evaluation_periods  = null // use default
    }
  }

  step_down = {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = null // use default
    step_adjustments = [
      {
        lower_bound        = null
        upper_bound        = 0
        scaling_adjustment = -1
      }
    ]

    alarm = {
      namespace = "AWS/ECS"
      dimensions = {
        ClusterName = module.fargate.ecs_cluster.name
        ServiceName = module.fargate.ecs_service.name
      }
      statistic           = null // use default
      metric_name         = "CPUUtilization"
      comparison_operator = "LessThanThreshold"
      threshold           = 25
      period              = null // use default
      evaluation_periods  = null // use default
    }
  }

  tags = local.tags
}

resource "aws_route53_record" "a_record" {
  name    = "${var.app_name}.${module.acs.route53_zone.name}"
  type    = "A"
  zone_id = module.acs.route53_zone.id
  alias {
    evaluate_target_health = true
    name                   = module.alb.alb.dns_name
    zone_id                = module.alb.alb.zone_id
  }
}
resource "aws_route53_record" "aaaa_record" {
  name    = "${var.app_name}.${module.acs.route53_zone.name}"
  type    = "AAAA"
  zone_id = module.acs.route53_zone.id
  alias {
    evaluate_target_health = true
    name                   = module.alb.alb.dns_name
    zone_id                = module.alb.alb.zone_id
  }
}