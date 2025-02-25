output "service_name" {
  value = aws_ecs_service.main.name
}

output "service_url" {
  value = aws_lb.alb_ecs.dns_name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.main.name
}

output "ecs_task_sg_id" {
  value = aws_security_group.sg_ecs_task_alb.id
}
