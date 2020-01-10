provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

data "aws_ecr_repository" "pre_made_repo" {
  name = "my-cool-repo"
}

module "fargate_api" {
//  source         = "git@github.com:byu-oit/terraform-aws-standard-fargate?ref=v0.3.0"
  source         = "../../" // for local testing
  app_name       = "example-api"
  env            = "dev"
  dockerfile_dir = "docker/"
  image_port     = 8000
  tags = {
    env              = "dev"
    data-sensitivity = "internal"
    repo             = "https://github.com/byu-oit/terraform-aws-standard-fargate"
  }
}

output "url" {
  value = module.fargate_api.dns_record
}

output "appspec" {
  value = module.fargate_api.codedeploy_appspec_json
}