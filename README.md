![Latest GitHub Release](https://img.shields.io/github/v/release/byu-oit/terraform-aws-standard-fargate?sort=semver)

# Terraform AWS Standard Fargate
Terraform module pattern to build a standard Fargate API.

This module creates a Fargate service with an ALB, AutoScaling, CodeDeploy configuration and a DNS record in front.

**Note:** This module has many preset standards to make creating an API using Fargate easy. If you require a more 
customized solution you may need to use this code more as a pattern or guideline in how to build the resources you need. 
 
## Usage
```hcl
module "my-app" {
  source = "git@github.com:byu-oit/terraform-aws-standard-fargate?ref=v0.2.0"
  app_name       = "example-api"
  env            = "dev"
  dockerfile_dir = "docker/"
  image_port     = 8000
}
```

## Created Resources
* ECR Repository
    * with an uploaded docker image
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
| Name | Type | Description | Default |
| --- | --- | --- | --- |
| app_name | string | Application name to name your Fargate API and other resources | |
| env | string | Environment of the AWS Account (e.g. dev, prd) | |
| dockerfile_dir | string | The directory that contains the Dockerfile to be built and then uploaded to ECR | |
| image_port | number | The port the docker image is listening on | |
| health_check_path | string | Health check path for the image | "/" |
| container_env_variables | map(string) | Map of environment variables to pass to the container definition | {} |
| container_secrets | map(string) | Map of secrets from the parameter store to be assigned to env variables. Use `task_policies` to make sure the Task's IAM role has access to the SSM parameters | {} |
| task_policies | list(string) | List of IAM Policy ARNs to attach to the task execution IAM Policy| [] |
| min_capacity | number | Minimum task count for autoscaling | 1 |
| max_capacity | number | Maximum task count for autoscaling | 2 | 

## Outputs
| Name | Type | Description |
| --- | --- | --- |
| fargate_service | [object](https://www.terraform.io/docs/providers/aws/r/ecs_service.html#attributes-reference) | Fargate ECS Service object |
| fargate_service_security_group | [object](https://www.terraform.io/docs/providers/aws/r/security_group.html#attributes-reference) assigned to the Fargate service | Security Group object |
| codedeploy_appspec_json | string | JSON string of a simple appspec.json file to be used in the CodeDeploy deployment |
| alb | [object](https://www.terraform.io/docs/providers/aws/r/lb.html#attributes-reference) | The Application Load Balancer (ALB) object |
| alb_security_group | [object](https://www.terraform.io/docs/providers/aws/r/security_group.html#attributes-reference) | The ALB's security group object |
| dns_record | [object](https://www.terraform.io/docs/providers/aws/r/route53_record.html#attributes-reference) | The DNS A-record mapped to the ALB | 
