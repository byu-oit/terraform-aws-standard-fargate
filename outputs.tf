output "fargate_service" {
  value = module.fargate.ecs_service
}

output "fargate_service_security_group" {
  value = module.fargate.service_sg
}

output "codedeploy_appspec_json" {
  value = module.fargate.codedeploy_appspec_json
}

output "alb" {
  value = module.alb.alb
}

output "alb_sg" {
  value = module.alb.alb_security_group
}

output "dns_record" {
  value = aws_route53_record.a_record
}