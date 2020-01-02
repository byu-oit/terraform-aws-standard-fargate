variable "app_name" {
  type        = string
  description = "Application name to name your Fargate API and other resources"
}

variable "image" {
  type = string
  description = "The docker image (including tag)"
}

variable "image_port" {
  type = number
  description = "The port the docker image is listening on"
}

variable "health_check_path" {
  type    = string
  default = "/"
  description = "Health check path for the image. Defaults to \"/\"."
}

variable "min_capacity" {
  type    = number
  default = 1
  description = "Minimum task count. Defaults to 1."
}

variable "max_capacity" {
  type    = number
  default = 2
  description = "Maximum task count. Defaults to 2."
}
