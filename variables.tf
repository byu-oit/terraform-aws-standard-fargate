variable "app_name" {
  type        = string
  description = "Application name to name your Fargate API and other resources. Must be <= 24 characters."
}
variable "dept_abbr" {
  type = string
  default = "oit"
  description = "Abbreviation of the department type of account (e.g. oit, trn), defaults to oit."
}
variable "env" {
  type        = string
  description = "Environment of the AWS Account (e.g. dev, prd)"
}

variable "container_image_url" {
  type        = string
  description = "URL to Docker container image"
}
variable "image_port" {
  type        = number
  description = "The port the docker image is listening on"
}
variable "health_check_path" {
  type        = string
  description = "Health check path for the image. Defaults to \"/\"."
  default     = "/"
}
variable "health_check_grace_period" {
  type        = number
  description = "Health check grace period in seconds. Defaults to 0."
  default     = 0
}
variable "container_env_variables" {
  type        = map(string)
  description = "Map of environment variables to pass to the container definition. Defaults to an empty map."
  default     = {}
}
variable "container_secrets" {
  type        = map(string)
  description = "Map of secrets from the parameter store to be assigned to an env variable. Defaults to an empty map."
  default     = {}
}
variable "task_policies" {
  type        = list(string)
  description = "List of IAM Policy ARNs to attach to the task execution policy."
  default     = []
}
variable "task_cpu" {
  type        = number
  description = "CPU for the task definition. Defaults to 256."
  default     = 256
}
variable "task_memory" {
  type        = number
  description = "Memory for the task definition. Defaults to 512."
  default     = 512
}
variable "security_groups" {
  type        = list(string)
  description = "List of extra security group IDs to attach to the fargate task."
  default     = []
}
variable "vpn_to_campus" {
  type        = bool
  description = "Do the Fargate tasks need to run in the VPC that has a VPN back to campus? Defaults to false."
  default     = false
}
variable "min_capacity" {
  type        = number
  description = "Minimum task count. Defaults to 1."
  default     = 1
}
variable "max_capacity" {
  type        = number
  description = "Maximum task count. Defaults to 2."
  default     = 2
}
variable "log_retention_in_days" {
  type        = number
  description = "CloudWatch log group retention in days. Defaults to 7."
  default     = 7
}
variable "tags" {
  type        = map(string)
  description = "A map of AWS Tags to attach to each resource created"
  default     = {}
}

variable "vpc_id" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "target_group_deregistration_delay" {
  type = number
  default = 60
}
variable "hosted_zone" {
  type = object({
    name = string,
    id = string
  })
}
variable "https_certificate_arn" {
  type = string
}
variable "role_permissions_boundary_arn" {
  type = string
}
variable "container_definitions" {
  type = string
}
variable "container_name" {
  type = string
}
variable "codedeploy_iam_role_arn" {
  type = string
}
