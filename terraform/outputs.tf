output "alb_dns_name" {
  description = "Public DNS name of the ALB (deployment link)"
  value       = aws_lb.main.dns_name
}