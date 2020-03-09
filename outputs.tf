output "fargate_service" {
  value = aws_ecs_service.service
}

output "fargate_service_security_group" {
  value = aws_security_group.fargate_service_sg
}

output "task_definition" {
  value = aws_ecs_task_definition.task_def
}

output "codedeploy_deployment_group" {
  value = aws_codedeploy_deployment_group.deploymentgroup
}

output "codedeploy_basic_appspec_json" {
  value = jsonencode({
    version = 1
    Resources = [{
      TargetService = {
        Type = "AWS::ECS::SERVICE"
        Properties = {
          TaskDefinition = aws_ecs_task_definition.task_def.arn
          LoadBalancerInfo = {
            ContainerName = local.container_definitions[0].name
            ContainerPort = var.image_port
          }
        }
      }
    }]
  })
}

output "alb" {
  value = aws_alb.alb
}

output "alb_sg" {
  value = aws_security_group.alb-sg
}

output "dns_record" {
  value = aws_route53_record.a_record
}
