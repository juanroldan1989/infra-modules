# Route 53 Failover Module

This module creates Route 53 DNS records with health checks for automatic failover between **primary** and **secondary** endpoints.

## Features

- ✅ **Automatic DNS failover** between primary and secondary endpoints
- ✅ **Health checks** with CloudWatch integration
- ✅ **Customizable health check parameters**
- ✅ **Support for ALB alias records**
- ✅ **CloudWatch alarms** for monitoring
- ✅ **Comprehensive outputs** for testing and monitoring

## Usage

```bash
module "route53_failover" {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/route53/failover"

  domain_name    = "myapp.example.com"
  hosted_zone_id = "Z1234567890ABC"
  env            = "prod"
  aws_account_id = "123456789012"

  primary_record = {
    name = "myapp.example.com"
    type = "A"
    alias = {
      name                   = "primary-alb.us-east-1.elb.amazonaws.com"
      zone_id               = "Z35SXDOTRQ7X7K"
      evaluate_target_health = true
    }
    set_identifier = "primary"
    failover_routing_policy = {
      type = "PRIMARY"
    }
  }

  dr_record = {
    name = "myapp.example.com"
    type = "A"
    alias = {
      name                   = "dr-alb.us-west-2.elb.amazonaws.com"
      zone_id               = "Z1H1FL5HABSF5"
      evaluate_target_health = true
    }
    set_identifier = "secondary"
    failover_routing_policy = {
      type = "SECONDARY"
    }
  }

  health_check = {
    fqdn              = "primary-alb.us-east-1.elb.amazonaws.com"
    port              = 80
    type              = "HTTP"
    resource_path     = "/health"
    failure_threshold = 3
    request_interval  = 30
    cloudwatch_alarm_region = "us-east-1"
    cloudwatch_alarm_name   = "myapp-health-check"
    insufficient_data_health_status = "Failure"
  }
}
```

## Testing

1. Test DNS resolution

```bash
nslookup myapp.example.com
```

2. Monitor failover

```bash
watch -n 10 'dig myapp.example.com +short'
```

3. Check health status

```bash
aws route53 get-health-check --health-check-id <health-check-id>
```

## Route 53 Health Check Configuration

### Valid `insufficient_data_health_status` Options

When configuring Route 53 health checks, the `insufficient_data_health_status` parameter accepts only these values:

#### **1. `"Healthy"` (Recommended for DR)**
```bash
insufficient_data_health_status = "Healthy"
```
**Behavior**: When Route 53 can't determine health status, it assumes **healthy**
- ✅ **Pros**: Prevents unnecessary failovers during monitoring issues
- ✅ **Good for**: Primary endpoints you trust to be stable
- ⚠️ **Cons**: May not failover during actual health check system issues

#### **2. `"Unhealthy"` (Conservative)**
```hcl
insufficient_data_health_status = "Unhealthy"
```
**Behavior**: When Route 53 can't determine health status, it assumes **unhealthy**
- ✅ **Pros**: Triggers failover when health check system has issues
- ✅ **Good for**: When you prefer to failover rather than risk serving from unhealthy endpoint
- ⚠️ **Cons**: May cause unnecessary failovers during Route 53 service issues

#### **3. `"LastKnownStatus"` (Balanced)**
```hcl
insufficient_data_health_status = "LastKnownStatus"
```
**Behavior**: Uses the **last known health status** when current data is unavailable
- ✅ **Pros**: Most stable option - maintains last known state
- ✅ **Good for**: Production systems where stability is key
- ⚠️ **Cons**: May maintain unhealthy status longer than desired

### Recommended Configuration for DR

For disaster recovery scenarios, use `"Healthy"` to prevent false failovers:

```bash
# Health check for primary region
health_check = {
  fqdn                            = dependency.primary_service_a.outputs.service_url
  port                            = 80
  type                            = "HTTP"
  resource_path                   = "/health"  # Use app health endpoint if available
  failure_threshold               = 3
  request_interval                = 30
  cloudwatch_alarm_region         = "us-east-1"
  cloudwatch_alarm_name           = "service-a-primary-health"
  insufficient_data_health_status = "Healthy"  # Prevents unnecessary failovers
}
```

### When Each Option Makes Sense

| Option | Best For | Use Case |
|--------|----------|----------|
| `"Healthy"` | **DR Primary** | Trust your primary service, only failover for real issues |
| `"Unhealthy"` | **Critical Systems** | Prefer failover over any uncertainty |
| `"LastKnownStatus"` | **Production** | Maximum stability, gradual state changes |

### Testing Implications

#### With `"Healthy"` (Recommended for Learning):
**These WILL trigger failover:**
- Stop your ECS service
- Break your ALB health checks
- Return 5xx errors from your app
- Block traffic with security groups

**These WON'T trigger failover:**
- Route 53 service issues
- Health check configuration problems
- Temporary monitoring glitches

#### With `"Unhealthy"` (More Aggressive):
**Additional triggers that cause failover:**
- Route 53 monitoring issues
- Health check service problems
- AWS API temporary issues
- Network connectivity to health check endpoints
