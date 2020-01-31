![Latest GitHub Release](https://img.shields.io/github/v/release/byu-oit/terraform-aws-standard-fargate?sort=semver)

# Terraform AWS Standard Fargate
Terraform module pattern to build a standard Fargate API.

This module creates a Fargate service with an ALB, AutoScaling, CodeDeploy configuration and a DNS record in front.

**Note:** This module has many preset standards to make creating an API using Fargate easy. If you require a more 
customized solution you may need to use this code more as a pattern or guideline in how to build the resources you need. 
 
## Usage
```hcl
module "my-app" {
  source = "github.com/byu-oit/terraform-aws-standard-fargate?ref=v1.0.2"
  app_name       = "example-api"
  env            = "dev"
  dockerfile_dir = "docker/"
  image_port     = 8000
  tags           = {
    repo = "https://github.com/byu-oit/my-cool-example-api"
  }
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

## Requirements
* Terraform version 0.12.16 or greater
* `bash`
* `aws` CLI
* `docker` (with the daemon running)
* `md5` or `md5sum`

## Inputs
| Name | Type | Description | Default |
| --- | --- | --- | --- |
| app_name | string | Application name to name your Fargate API and other resources | |
| env | string | Environment of the AWS Account (e.g. dev, prd) | |
| container_image_url | string | URL to Docker container image including image tag | |
| image_port | number | The port the docker image is listening on | |
| health_check_path | string | Health check path for the image | "/" |
| health_check_grace_period | number | Health check grace period in seconds| 0 |
| container_env_variables | map(string) | Map of environment variables to pass to the container definition | {} |
| container_secrets | map(string) | Map of secrets from the parameter store to be assigned to env variables. Use `task_policies` to make sure the Task's IAM role has access to the SSM parameters | {} |
| task_policies | list(string) | List of IAM Policy ARNs to attach to the task execution IAM Policy| [] |
| task_cpu | number | CPU for the task definition | 256 |
| task_memory | number | Memory for the task definition | 512 |
| security_groups | list(string) | List of extra security group IDs to attach to the fargate task | []|
| vpn_to_campus | bool | Do the Fargate tasks need to run in the VPC that has a VPN back to campus? | false |
| min_capacity | number | Minimum task count for autoscaling | 1 |
| max_capacity | number | Maximum task count for autoscaling | 2 | 
| log_retention_in_days | number | CloudWatch log group retention in days | 7 |
| tags | map(string) | A map of AWS Tags to attach to each resource created | {} |

#### container_image_url
This can be the ecr_image_url with the tag like:
```
<acct_num>.dkr.ecr.us-west-2.amazonaws.com/myapp:dev
```
or it can be just the image URL from dockerHub or some other docker registry.

This module will attempt to create the ECS Fargate Service looking at this image url. If there are no images uploaded to
the URL then ECS will continue to try starting the task until an image exists. 

**Before running this configuration** make sure that your ECR repo exists and an image has been pushed to the repo.

#### tags
Follow the [tagging standard](https://github.com/byu-oit/BYU-AWS-Documentation#tagging-standard). Some tags will be defaulted but can be overridden.
* `env` defaults to the input variable `env`
* `data-sensitivity` defaults to "confidential"

## Outputs
| Name | Type | Description |
| --- | --- | --- |
| fargate_service | [object](https://www.terraform.io/docs/providers/aws/r/ecs_service.html#attributes-reference) | Fargate ECS Service object |
| fargate_service_security_group | [object](https://www.terraform.io/docs/providers/aws/r/security_group.html#attributes-reference) | Security Group object assigned to the Fargate service |
| codedeploy_appspec_json | string | JSON string of a simple appspec.json file to be used in the CodeDeploy deployment |
| alb | [object](https://www.terraform.io/docs/providers/aws/r/lb.html#attributes-reference) | The Application Load Balancer (ALB) object |
| alb_security_group | [object](https://www.terraform.io/docs/providers/aws/r/security_group.html#attributes-reference) | The ALB's security group object |
| dns_record | [object](https://www.terraform.io/docs/providers/aws/r/route53_record.html#attributes-reference) | The DNS A-record mapped to the ALB | 

## Note
If you require additional variables please create an [issue](https://github.com/byu-oit/terraform-aws-standard-fargate/issues)
 and/or a [pull request](https://github.com/byu-oit/terraform-aws-standard-fargate/pulls) to add the variable and reach 
 out to the Terraform Working Group on slack (`#terraform` channel).
