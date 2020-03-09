variable "app_name" {
  type        = string
  description = "Application name to name your Fargate API and other resources. Must be <= 24 characters."
}
variable "container_definitions" {
  type = list(object({
    name                  = string
    image                 = string
    ports                 = list(number)
    environment_variables = map(string)
    secrets               = map(string)
  }))
  description = "A list of container definitions. The first container definition should be your main container."
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
variable "vpc_id" {
  type        = string
  description = "VPC ID to deploy ECS fargate service."
}
variable "public_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the ALB."
}
variable "private_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the fargate service."
}
variable "role_permissions_boundary_arn" {
  type        = string
  description = "ARN of the IAM Role permissions boundary to place on each IAM role created."
}
variable "target_group_deregistration_delay" {
  type        = number
  description = "Deregistration delay in seconds for ALB target groups. Defaults to 60 seconds."
  default     = 60
}
variable "hosted_zone" {
  type = object({
    name = string,
    id   = string
  })
  description = "Hosted Zone object to redirect to ALB. (Can pass in the aws_hosted_zone object). A and AAAA records created in this hosted zone."
}
variable "https_certificate_arn" {
  type        = string
  description = "ARN of the HTTPS certificate of the hosted zone/domain."
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
