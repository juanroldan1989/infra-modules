variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the DNS records"
  type        = string

  validation {
    condition     = can(regex("^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid FQDN (e.g., 'example.com', 'subdomain.example.com', 'service-a-dev.automata-labs.nl')."
  }
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
}

variable "primary_record" {
  description = "Configuration for primary DNS record"
  type = object({
    name    = string
    type    = string
    alias = object({
      name                   = string
      zone_id               = string
      evaluate_target_health = bool
    })
    set_identifier = string
    failover_routing_policy = object({
      type = string
    })
  })

  validation {
    condition     = contains(["PRIMARY"], var.primary_record.failover_routing_policy.type)
    error_message = "Primary record must have failover_routing_policy.type = 'PRIMARY'."
  }
}

variable "dr_record" {
  description = "Configuration for DR (secondary) DNS record"
  type = object({
    name    = string
    type    = string
    alias = object({
      name                   = string
      zone_id               = string
      evaluate_target_health = bool
    })
    set_identifier = string
    failover_routing_policy = object({
      type = string
    })
  })

  validation {
    condition     = contains(["SECONDARY"], var.dr_record.failover_routing_policy.type)
    error_message = "DR record must have failover_routing_policy.type = 'SECONDARY'."
  }
}

variable "health_check" {
  description = "Health check configuration for primary endpoint"
  type = object({
    fqdn                            = string
    port                            = number
    type                            = string
    resource_path                   = string
    failure_threshold               = number
    request_interval                = number
    cloudwatch_alarm_region         = string
    cloudwatch_alarm_name           = string
    insufficient_data_health_status = string
  })

  default = {
    fqdn                            = ""
    port                            = 80
    type                            = "HTTP"
    resource_path                   = "/health"
    failure_threshold               = 3
    request_interval                = 30
    cloudwatch_alarm_region         = "us-east-1"
    cloudwatch_alarm_name           = "route53-health-check"
    insufficient_data_health_status = "Healthy" # Options: "Healthy", "Unhealthy", "LastKnownStatus"
  }

  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP"], var.health_check.type)
    error_message = "Health check type must be HTTP, HTTPS, or TCP."
  }

  validation {
    condition     = var.health_check.failure_threshold >= 1 && var.health_check.failure_threshold <= 10
    error_message = "Failure threshold must be between 1 and 10."
  }

  validation {
    condition     = contains([10, 30], var.health_check.request_interval)
    error_message = "Request interval must be either 10 or 30 seconds."
  }
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

variable "create_cname_record" {
  description = "Whether to create a CNAME record for easier app access"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
