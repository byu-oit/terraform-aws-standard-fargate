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
  value = local_file.appspec_json.content
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
