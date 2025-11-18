output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = var.hosted_zone_id
}

output "domain_name" {
  description = "The domain name configured"
  value       = var.domain_name
}

output "primary_record_name" {
  description = "Primary DNS record name"
  value       = aws_route53_record.primary.name
}

output "primary_record_fqdn" {
  description = "Primary DNS record FQDN"
  value       = aws_route53_record.primary.fqdn
}

output "secondary_record_name" {
  description = "Secondary (DR) DNS record name"
  value       = aws_route53_record.secondary.name
}

output "secondary_record_fqdn" {
  description = "Secondary (DR) DNS record FQDN"
  value       = aws_route53_record.secondary.fqdn
}

output "health_check_id" {
  description = "Route 53 health check ID"
  value       = aws_route53_health_check.primary.id
}

output "health_check_arn" {
  description = "Route 53 health check ARN"
  value       = aws_route53_health_check.primary.arn
}

output "cloudwatch_alarm_arn" {
  description = "CloudWatch alarm ARN for health check"
  value       = aws_cloudwatch_metric_alarm.primary_health.arn
}

output "cloudwatch_alarm_name" {
  description = "CloudWatch alarm name"
  value       = aws_cloudwatch_metric_alarm.primary_health.alarm_name
}

# Primary endpoint information
output "primary_endpoint" {
  description = "Primary endpoint details"
  value = {
    name    = var.primary_record.alias.name
    zone_id = var.primary_record.alias.zone_id
    type    = "PRIMARY"
  }
}

# DR endpoint information
output "dr_endpoint" {
  description = "DR endpoint details"
  value = {
    name    = var.dr_record.alias.name
    zone_id = var.dr_record.alias.zone_id
    type    = "SECONDARY"
  }
}

# Health check configuration
output "health_check_config" {
  description = "Health check configuration details"
  value = {
    fqdn              = aws_route53_health_check.primary.fqdn
    port              = aws_route53_health_check.primary.port
    type              = aws_route53_health_check.primary.type
    resource_path     = aws_route53_health_check.primary.resource_path
    failure_threshold = aws_route53_health_check.primary.failure_threshold
    request_interval  = aws_route53_health_check.primary.request_interval
  }
}

# DNS resolution test commands
output "dns_test_commands" {
  description = "Commands to test DNS resolution"
  value = {
    nslookup = "nslookup ${var.domain_name}"
    dig      = "dig ${var.domain_name} +short"
    curl     = "curl -I http://${var.domain_name}${var.health_check.resource_path}"
  }
}

# Failover testing information
output "failover_test_info" {
  description = "Information for testing failover scenarios"
  value = {
    health_check_url = "${var.health_check.type == "HTTPS" ? "https" : "http"}://${var.health_check.fqdn}:${var.health_check.port}${var.health_check.resource_path}"
    expected_rto     = "3-5 minutes"
    expected_rpo     = "0 seconds (stateless)"
    monitoring_commands = [
      "watch -n 10 'dig ${var.domain_name} +short'",
      "aws route53 get-health-check --health-check-id ${aws_route53_health_check.primary.id}",
      "aws cloudwatch get-metric-statistics --namespace AWS/Route53 --metric-name HealthCheckStatus --dimensions Name=HealthCheckId,Value=${aws_route53_health_check.primary.id} --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average"
    ]
  }
}
