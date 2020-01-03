![Latest GitHub Release](https://img.shields.io/github/v/release/byu-oit/terraform-aws-standard-fargate?sort=semver)

# Terraform AWS Standard Fargate
Terraform module pattern to build a standard Fargate API.

This module creates a Fargate service with an ALB, AutoScaling, CodeDeploy configuration and a DNS record in front.

**Note:** This module has many preset standards to make creating an API using Fargate easy. If you require a more 
customized solution you may need to use this code more as a pattern or guideline in how to build the resources you need. 
 
## Usage
```hcl
module "my-app" {
  source = "git@github.com:byu-oit/terraform-aws-standard-fargate?ref=v0.1.0"
  app_name = "example-api"
  image = "${data.aws_ecr_repository.pre_made_repo.repository_url}:init"
  image_port = 8000
}
```

**Note:** If you are going to use ECR to host the docker image, you will need to have the repository created and image 
uploaded before you run this module. This module does not create the ECR repository in order to avoid a chicken-and-the-egg 
predicament of when to actually upload the image to ECR 

## Created Resources
* ECS Cluster
* ECS Service
    * with security group
* ECS Task Definition
    * with IAM role
* CloudWatch Log Group
* ALB
    * with security group
* 2 Target Groups (for blue-green deployment)
* CodeDeploy App
    * with IAM role
* CodeDeploy Group
* DNS A-Record
* AutoScaling Target
* AutoScaling Policies (one for stepping up and one for stepping down)
* CloudWatch Metric Alarms (one for stepping up and one for stepping down)

## Inputs
| Name | Description | Default |
| --- | --- | --- |
| app_name | Application name to name your Fargate API and other resources | |
| image | The docker image (including tag). Include the full URI if not pulling from docker hub | |
| image_port | The port the docker image is listening on | |
| health_check_path | Health check path for the image | "/" |
| container_env_variables | Map of environment variables to pass to the container definition | {} |
| container_secrets | Map of secrets from the parameter store to be assigned to env variables. Use `task_policies` to make sure the Task's IAM role has access to the SSM parameters | {} |
| min_capacity | Minimum task count for autoscaling | 1 |
| max_capacity | Maximum task count for autoscaling | 2 | 

## Outputs
| Name | Description |
| --- | --- |
| fargate_service | Fargate ECS Service [object](https://www.terraform.io/docs/providers/aws/r/ecs_service.html#attributes-reference) |
| fargate_service_security_group | Security Group [object](https://www.terraform.io/docs/providers/aws/r/security_group.html#attributes-reference) assigned to the Fargate service |
| codedeploy_appspec_json | JSON string of a simple appspec.json file to be used in the CodeDeploy deployment |
| alb | The Application Load Balancer (ALB) [object](https://www.terraform.io/docs/providers/aws/r/lb.html#attributes-reference) |
| alb_security_group | The ALB's security group [object](https://www.terraform.io/docs/providers/aws/r/security_group.html#attributes-reference) |
| dns_record | The DNS A-record mapped to the ALB | 
