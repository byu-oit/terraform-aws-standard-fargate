provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v2.0.0"
}

module "fargate_api" {
  //    source         = "github.com/byu-oit/terraform-aws-standard-fargate?ref=v2.0.0"
  source     = "../../" // for local testing
  app_name   = "example-api"
  image_port = 8000
  container_definitions = [{
    name  = "example"
    image = "crccheck/hello-world"
    ports = [8000]
    environment_variables = {
      env = "tst"
    }
    secrets = {
      foo = "/super-secret"
    }
  }]
  autoscaling_config            = null
  codedeploy_test_listener_port = 8080
  codedeploy_lifecycle_hooks = [
    {
      lifecycle_hook       = "AfterAllowTestTraffic"
      lambda_function_name = "testLifecycle"
    }
  ]

  hosted_zone                   = module.acs.route53_zone
  https_certificate_arn         = module.acs.certificate.arn
  public_subnet_ids             = module.acs.public_subnet_ids
  private_subnet_ids            = module.acs.private_subnet_ids
  vpc_id                        = module.acs.vpc.id
  codedeploy_service_role_arn   = module.acs.power_builder_role.arn
  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn

  tags = {
    env              = "dev"
    data-sensitivity = "internal"
    repo             = "https://github.com/byu-oit/terraform-aws-standard-fargate"
  }
}

output "url" {
  value = module.fargate_api.dns_record.fqdn
}

output "appspec_filename" {
  value = module.fargate_api.codedeploy_appspec_json_file
}
