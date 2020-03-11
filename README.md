![Latest GitHub Release](https://img.shields.io/github/v/release/byu-oit/terraform-aws-standard-fargate?sort=semver)

# Terraform AWS Standard Fargate
Terraform module pattern to build a standard Fargate API.

This module creates a Fargate service with an ALB, AutoScaling, CodeDeploy configuration and a DNS record in front.

**Note:** This module has many preset standards to make creating an API using Fargate easy. If you require a more 
customized solution you may need to use this code more as a pattern or guideline in how to build the resources you need. 
 
## Usage
```hcl
module "my-app" {
  source = "github.com/byu-oit/terraform-aws-standard-fargate?ref=v2.0.0"
  app_name   = "example-api"
    image_port = 8000
    container_definitions = [{
      name  = "example"
      image = "crccheck/hello-world"
      ports = [8000]
      environment_variables = {}
      secrets = {}
    }]
  
    hosted_zone                   = module.acs.route53_zone
    https_certificate_arn         = module.acs.certificate.arn
    public_subnet_ids             = module.acs.public_subnet_ids
    private_subnet_ids            = module.acs.private_subnet_ids
    vpc_id                        = module.acs.vpc.id
    role_permissions_boundary_arn = module.acs.role_permissions_boundary.arn
  
    tags = {
      env              = "dev"
      data-sensitivity = "internal"
      repo             = "https://github.com/byu-oit/terraform-aws-standard-fargate"
    }
}
```

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

## Requirements
* Terraform version 0.12.16 or greater

## Inputs
| Name | Type | Description | Default |
| --- | --- | --- | --- |
| app_name | string | Application name to name your Fargate API and other resources (Must be <= 24 alphanumeric characters) | |
| container_definitions | [list(object)](#container_definitions) | List of container definitions defining the docker container to run | |
| image_port | number | The port the main docker image is listening on | |
| health_check_path | string | Health check path for the image | "/" |
| health_check_interval | number | Amount of time, in seconds, between health checks of an individual target | 30 |
| health_check_timeout | number | Amount of time, in seconds, during which no response means a failed health check | 5 |
| health_check_healthy_threshold | number | Number of consecutive health checks required before considering target as healthy | 3 |
| health_check_unhealthy_threshold | number | Number of consecutive failed health checks required before considering target as unhealthy | 3 |
| health_check_grace_period | number | Health check grace period in seconds| 0 |
| task_policies | list(string) | List of IAM Policy ARNs to attach to the task execution IAM Policy| [] |
| task_cpu | number | CPU for the task definition | 256 |
| task_memory | number | Memory for the task definition | 512 |
| security_groups | list(string) | List of extra security group IDs to attach to the fargate task | []|
| vpc_id | string | VPC ID to deploy the ECS fargate service and ALB | |
| public_subnet_ids | list(string) | List of subnet IDs for the ALB | |
| private_subnet_ids | list(string) | List of subnet IDs for the fargate service | |
| codedeploy_service_role_arn | string | ARN of the IAM Role for the CodeDeploy to use to initiate new deployments. (usually the PowerBuilder Role) | |
| codedeploy_termination_wait_time | number | the number of minutes to wait after a successful blue/green deployment before terminating instances from the original environment | 15 |
| role_permissions_boundary_arn | string | ARN of the IAM Role permissions boundary to place on each IAM role created | |
| target_group_deregistration_delay | number | Deregistration delay in seconds for ALB target groups | 60 |
| hosted_zone | [object](#hosted_zone) | Hosted Zone object to redirect to ALB. (Can pass in the aws_hosted_zone object). A and AAAA records created in this hosted zone | |
| https_certificate_arn | string | ARN of the HTTPS certificate of the hosted zone/domain | |
| autoscaling_config | [object](#autoscaling_config) | Configuration for default autoscaling policies and alarms. Set to `null` if you want to set up your own autoscaling policies and alarms.  | |
| log_retention_in_days | number | CloudWatch log group retention in days | 7 |
| tags | map(string) | A map of AWS Tags to attach to each resource created | {} |

#### container_definitions
List of objects with following attributes to define the docker container(s) your fargate needs to run.
* **`name`** - (Required) container name (referenced in CloudWatch logs, and possibly by other containers)
* **`image`** - (Required) the ecr_image_url with the tag like: `<acct_num>.dkr.ecr.us-west-2.amazonaws.com/myapp:dev` or the image URL from dockerHub or some other docker registry
* **`ports`** - (Required) a list of ports this container is listening on
* **`environment_variables`** - (Required) a map of environment variables to pass to the docker container
* **`secrets`** - (Required) a map of secrets from the parameter store to be assigned to env variables

**Before running this configuration** make sure that your ECR repo exists and an image has been pushed to the repo.

#### hosted_zone
You can pass in either the object from the AWS terraform provider for an AWS Hosted Zone, or just an object with the following attributes:
* **`name`** - (Required) Name of the hosted zone
* **`id`** - (Required) ID of the hosted zone

#### autoscaling_config
This module will create basic default autoscaling policies and alarms and you can define some variables of these default autoscaling policies.
* **`min_capacity`** - (Required) Minimum task count for autoscaling (this will also be used to define the initial desired count of the ECS Fargate Service)
* **`max_capacity`** - (Required) Maximum task count for autoscaling

**Note:** If you want to define your own autoscaling policies/alarms then you need to set this field to `null` at which point this module will not create any policies/alarms.

**Note:** the desired count of the ECS Fargate Service will be set the first time terraform runs but changes to desired count will be ignored after the first time.  

#### CloudWatch logs
This module will create a CloudWatch log group named `fargate/<app_name>` with log streams named `<app_name>/<container_name>/<container_id>`. 

For instance with the [above example](#usage) the logs could be found in the CloudWatch log group: `fargate/example-api` with the container logs in `example-api/example/12d344fd34b556ae4326...` 

## Outputs
| Name | Type | Description |
| --- | --- | --- |
| fargate_service | [object](https://www.terraform.io/docs/providers/aws/r/ecs_service.html#attributes-reference) | Fargate ECS Service object |
| fargate_service_security_group | [object](https://www.terraform.io/docs/providers/aws/r/security_group.html#attributes-reference) | Security Group object assigned to the Fargate service |
| task_definition | [object](https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html#attributes-reference) | The task definition object of the fargate service |
| codedeploy_deployment_group | [object](https://www.terraform.io/docs/providers/aws/r/codedeploy_deployment_group.html#attributes-reference) | The CodeDeploy deployment group object. |
| alb | [object](https://www.terraform.io/docs/providers/aws/r/lb.html#attributes-reference) | The Application Load Balancer (ALB) object |
| alb_security_group | [object](https://www.terraform.io/docs/providers/aws/r/security_group.html#attributes-reference) | The ALB's security group object |
| dns_record | [object](https://www.terraform.io/docs/providers/aws/r/route53_record.html#attributes-reference) | The DNS A-record mapped to the ALB | 

#### appspec
This module also creates a JSON file in the project directory: `appspec.json` used to initiate a CodeDeploy Deployment.

The appspec file generated by this module is just the bare bones of an appspec file but could be used as is to deploy a new version of of your fargate service.
You can add more to the appspec file in order to tie into [CodeDeploy's lifecycle hooks](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-ecs).

Here's an example appspec.json file this creates:
```json
{
  "Resources": [
    {
      "TargetService": {
        "Properties": {
          "LoadBalancerInfo": {
            "ContainerName": "example",
            "ContainerPort": 8000
          },
          "TaskDefinition": "arn:aws:ecs:us-west-2:123456789123:task-definition/example-api-def:2"
        },
        "Type": "AWS::ECS::SERVICE"
      }
    }
  ],
  "version": 1
}
```

## Note
If you require additional variables please create an [issue](https://github.com/byu-oit/terraform-aws-standard-fargate/issues)
 and/or a [pull request](https://github.com/byu-oit/terraform-aws-standard-fargate/pulls) to add the variable and reach 
 out to the Terraform Working Group on slack (`#terraform` channel).
