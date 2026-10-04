output "alb_dns_name" {
  description = "Public DNS name of the ALB (deployment link)"
  value       = aws_lb.main.dns_name
}

output "app_url" {
  description = "URL to open the deployed app"
  value       = "http://${aws_lb.main.dns_name}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "ecr_repository_url" {
  description = "ECR repository URL (docker push target)"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name (ECR_REPOSITORY in cd.yml)"
  value       = aws_ecr_repository.app.name
}

output "ecs_cluster_name" {
  description = "ECS cluster name (ECS_CLUSTER in cd.yml)"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name (ECS_SERVICE in cd.yml)"
  value       = aws_ecs_service.app.name
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC (secret AWS_ROLE_ARN)"
  value       = aws_iam_role.github_actions.arn
}