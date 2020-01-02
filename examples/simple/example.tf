provider "aws" {
  region = "us-west-2"
}

data "aws_ecr_repository" "pre_made_repo" {
  name = "my-cool-repo"
}

module "fargate_api" {
  source     = "../../"
  app_name   = "example-api"
  image      = "${data.aws_ecr_repository.pre_made_repo.repository_url}:test"
  image_port = 8000
}

output "appspec" {
  value = module.fargate_api.appspec
}