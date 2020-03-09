provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v1.2.2"
  env = "dev"
  dept_abbr = "ces"
}

//module "container_def" {
//  source = "github.com/byu-oit/terraform-aws-container-definition-helper?ref=v0.1.1"
//  image  = "crccheck/hello-world"
//  name   = "example"
//  ports  = [8000]
//}

module "fargate_api" {
//  source         = "github.com/byu-oit/terraform-aws-standard-fargate?ref=v2.0.0"
  source         = "../../" // for local testing
  app_name       = "example-api"
  env            = "dev"
//  container_image_url = "crccheck/hello-world"
  image_port     = 8000
//  container_name = "example"
//  container_definitions = "[${module.container_def.json}]"
  container_definitions = [{
    name = "example"
    image = "crccheck/hello-world"
    ports = [8000]
    environment_variables = {
      env = "dev"
    }
    secrets = {
      foo = "/super-secret"
    }
  }]

  hosted_zone = module.acs.route53_zone
  https_certificate_arn = module.acs.certificate.arn
  public_subnet_ids = module.acs.public_subnet_ids
  private_subnet_ids = module.acs.private_subnet_ids
  vpc_id = module.acs.vpc.id
  role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn
  codedeploy_iam_role_arn = module.acs.power_builder_role.arn

  tags = {
    env              = "dev"
    data-sensitivity = "internal"
    repo             = "https://github.com/byu-oit/terraform-aws-standard-fargate"
  }
}

output "url" {
  value = module.fargate_api.dns_record
}

//output "appspec" {
//  value = module.fargate_api.codedeploy_appspec_json
//}
