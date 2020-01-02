provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

data "aws_ecr_repository" "pre_made_repo" {
  name = "my-cool-repo"
}

module "fargate_api" {
  source = "git@github.com:byu-oit/terraform-aws-standard-fargate?ref=v1.0.0"
//  source     = "../../" // for local testing
  app_name   = "example-api"
  image      = "${data.aws_ecr_repository.pre_made_repo.repository_url}:test"
  image_port = 8000
}

output "appspec" {
  value = module.fargate_api.appspec
}