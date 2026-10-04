locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = "Golden Owl DevOps Internship"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}