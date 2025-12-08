output "grafana_url" {
  description = "Grafana URL"
  value       = "http://${aws_lb.grafana_alb.dns_name}"
}

output "grafana_alb_dns" {
  description = "Grafana ALB DNS name"
  value       = aws_lb.grafana_alb.dns_name
}

output "grafana_alb_zone_id" {
  description = "Grafana ALB zone ID"
  value       = aws_lb.grafana_alb.zone_id
}

output "grafana_service_name" {
  description = "Grafana ECS service name"
  value       = aws_ecs_service.grafana.name
}

output "grafana_log_group" {
  description = "Grafana CloudWatch log group"
  value       = aws_cloudwatch_log_group.grafana.name
}

output "grafana_efs_id" {
  description = "Grafana EFS file system ID"
  value       = aws_efs_file_system.grafana.id
}
