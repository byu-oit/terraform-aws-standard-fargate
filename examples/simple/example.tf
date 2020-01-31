provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

module "fargate_api" {
  source         = "github.com/byu-oit/terraform-aws-standard-fargate?ref=v1.0.2"
//  source         = "../../" // for local testing
  app_name       = "example-api"
  env            = "dev"
  container_image_url = "crccheck/hello-world"
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
