variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Prefix for resource names"
  type        = string
  default     = "goldenowl-internship"
}

variable "environment" {
  description = "Environment name used in names and tags"
  type        = string
  default     = "staging"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets, one per availability zone"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "container_port" {
  description = "Port the Node.js app listens on"
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "Path the ALB uses to health check the app"
  type        = string
  default     = "/"
}

variable "github_repository" {
  type = object({
    owner    = string
    owner_id = string
    repo     = string
    repo_id  = string
  })

  default = {
    owner    = "Nguyen-Thanh-Huy-io"
    owner_id = "188283969"
    repo     = "goldenowl-devops-internship-challenge"
    repo_id  = "1402822141"
  }
}

variable "container_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Initial number of tasks (0 until the first image is pushed to ECR)"
  type        = number
  default     = 0
}

variable "min_capacity" {
  description = "Autoscaling minimum number of tasks"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Autoscaling maximum number of tasks"
  type        = number
  default     = 4
}

variable "cpu_target_value" {
  description = "Target average CPU utilization (%) for target tracking"
  type        = number
  default     = 60
}