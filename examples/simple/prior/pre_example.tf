provider "aws" {
  region = "us-west-2"
}

module "ecr" {
  source               = "git@github.com:byu-oit/terraform-aws-ecr.git?ref=v1.0.0"
  name                 = "my-cool-repo"
  image_tag_mutability = "IMMUTABLE"
  scan_image_on_push   = true
}

output "repo_name" {
  value = module.ecr.repository.name
}