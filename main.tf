terraform {
  required_version = ">= 0.12.16"
  required_providers {
    aws = ">= 2.42"
  }
}

module "acs" {
  source = "git@github.com:byu-oit/terraform-aws-acs-info.git?ref=v1.0.5"
  env    = "dev"
}

module "alb" {
  source     = "git@github.com:byu-oit/terraform-aws-alb.git?ref=v1.1.0"
  name       = "${var.app_name}-alb"
  vpc_id     = module.acs.vpc.id
  subnet_ids = module.acs.public_subnet_ids
  default_target_group_config = {
    type                 = "ip"
    deregistration_delay = null
    slow_start           = null
    health_check = {
      path                = var.health_check_path
      interval            = null
      timeout             = null
      healthy_threshold   = null
      unhealthy_threshold = null
    }
    stickiness_cookie_duration = null
  }
  target_groups = [
    {
      name_suffix    = "blue"
      listener_ports = [80]
      port           = var.image_port
      config         = null
    },
    {
      name_suffix    = "green"
      listener_ports = []
      port           = var.image_port
      config         = null
    }
  ]
}

module "fargate" {
  source              = "git@github.com:byu-oit/terraform-aws-fargate.git?ref=v1.0.0"
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
  container_image = var.image

  blue_green_deployment_config = {
    termination_wait_time_after_deployment_success = null // defaults to 15
    prod_traffic_listener_arns                     = [module.alb.listeners[80].arn]
    test_traffic_listener_arns                     = []
    blue_target_group_name                         = module.alb.target_groups["blue"].name
    green_target_group_name                        = module.alb.target_groups["green"].name
  }

  module_depends_on = [module.alb.alb]
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