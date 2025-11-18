# Health Check for Primary Region
resource "aws_route53_health_check" "primary" {
  fqdn                            = var.health_check.fqdn
  port                            = var.health_check.port
  type                            = var.health_check.type
  resource_path                   = var.health_check.resource_path
  failure_threshold               = var.health_check.failure_threshold
  request_interval                = var.health_check.request_interval
  cloudwatch_alarm_region         = var.health_check.cloudwatch_alarm_region
  insufficient_data_health_status = var.health_check.insufficient_data_health_status

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-primary-health-check"
      Environment = var.env
      Type        = "Primary"
      Region      = var.health_check.cloudwatch_alarm_region
    }
  )
}

# CloudWatch Alarm for Health Check
resource "aws_cloudwatch_metric_alarm" "primary_health" {
  alarm_name          = var.health_check.cloudwatch_alarm_name
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This metric monitors the health of ${var.domain_name} primary endpoint"
  alarm_actions       = var.alarm_actions

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-primary-alarm"
      Environment = var.env
      Type        = "HealthCheck"
    }
  )
}

# Primary DNS Record (PRIMARY failover)
resource "aws_route53_record" "primary" {
  zone_id        = var.hosted_zone_id
  name           = var.primary_record.name
  type           = var.primary_record.type
  set_identifier = var.primary_record.set_identifier

  alias {
    name                   = var.primary_record.alias.name
    zone_id                = var.primary_record.alias.zone_id
    evaluate_target_health = var.primary_record.alias.evaluate_target_health
  }

  failover_routing_policy {
    type = var.primary_record.failover_routing_policy.type
  }

  health_check_id = aws_route53_health_check.primary.id

  depends_on = [aws_route53_health_check.primary]
}

# DR DNS Record (SECONDARY failover)
resource "aws_route53_record" "secondary" {
  zone_id        = var.hosted_zone_id
  name           = var.dr_record.name
  type           = var.dr_record.type
  set_identifier = var.dr_record.set_identifier

  alias {
    name                   = var.dr_record.alias.name
    zone_id                = var.dr_record.alias.zone_id
    evaluate_target_health = var.dr_record.alias.evaluate_target_health
  }

  failover_routing_policy {
    type = var.dr_record.failover_routing_policy.type
  }

  # Secondary record doesn't need health check - it's the fallback
  # health_check_id is optional for SECONDARY records
}

# Optional: CNAME record for easier management
resource "aws_route53_record" "cname" {
  count = var.create_cname_record ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = "app.${var.domain_name}"
  type    = "CNAME"
  ttl     = 60
  records = [var.domain_name]
}
