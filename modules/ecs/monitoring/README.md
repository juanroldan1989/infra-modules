# Grafana Monitoring Module

This Terraform module deploys Grafana on Amazon ECS to monitor your ECS cluster services and AWS resources.

## Features

- **Grafana Container** - Latest Grafana image with CloudWatch datasource
- **Persistent Storage** - EFS for dashboards, users, and configurations
- **Secure Access** - Password stored in AWS Secrets Manager
- **CloudWatch Integration** - Pre-configured IAM permissions to query metrics
- **ECS Monitoring** - Monitor all services in your ECS cluster
- **Load Balanced** - Internet-facing ALB for external access
- **Production Ready** - Encrypted storage, proper security groups, and logging

## Architecture

```
Internet → ALB (Public Subnets) → Grafana Container (Private Subnets)
                                        ↓
                                   EFS Storage
                                        ↓
                              CloudWatch Datasource
                                        ↓
                              ECS Services Metrics
```

## Resources Created

1. **ECS Service** (`aws_ecs_service.grafana`)
2. **ECS Task Definition** (`aws_ecs_task_definition.grafana`)
3. **Application Load Balancer** (`aws_lb.grafana_alb`)
4. **Target Group** (`aws_lb_target_group.grafana`)
5. **Security Groups**:
   - Grafana tasks (`aws_security_group.grafana`)
   - ALB (`aws_security_group.grafana_alb`)
   - EFS (`aws_security_group.efs`)
6. **EFS File System** (`aws_efs_file_system.grafana`)
7. **EFS Access Point** (`aws_efs_access_point.grafana`)
8. **IAM Roles**:
   - Execution role for ECS
   - Task role with CloudWatch permissions
9. **Secrets Manager** - Grafana admin password
10. **CloudWatch Log Group** - Container logs

## Dependencies

This module has the following dependencies:

- AWS ECS Cluster
- VPC and Subnets
- IAM Roles and Policies for ECS tasks and services

## Diagram

```bash
                                    +-----------------------------+
                                    |        AWS Internet         |
                                    +-----------------------------+
                                               |
                                               v
                                  +----------------------------+
                                  |        ALB (aws_lb)        |
                                  +----------------------------+
                                      |                  |
                         +--------------------+  +----------------------+
                         | ALB Listener (80)  |  | ALB Listener (443)   |
                         +--------------------+  +----------------------+
                                      |
                                      v
                        +-----------------------------+
                        | Target Group (tg_alb_http)  |
                        +-----------------------------+
                                      |
                                      v
                          +-------------------------+
                          | ECS Service (ecs_main)  |
                          +-------------------------+
                              |                |
                +------------------------+  +--------------------+
                | Subnets (var.subnet_ids)  | Security Group     |
                +------------------------+  +--------------------+
                                                      |
                                                      v
                                        +-----------------------------+
                                        | ECS Task Definition (app)   |
                                        |  - Container (app)          |
                                        |  - CPU: var.container_cpu   |
                                        |  - Memory: var.container_mem|
                                        |  - Port: var.container_port |
                                        +-----------------------------+
                                                      |
                                                      v
                                        +-------------------------+
                                        | CloudWatch Log Group    |
                                        +-------------------------+
                                                      |
                                        +-------------------------+
                                        | CloudWatch Log Stream   |
                                        +-------------------------+
```

Explanation:

1. AWS Internet: Represents incoming traffic from the internet.

2. ALB (Application Load Balancer): Handles HTTP/HTTPS requests and forwards them to the target group.

3. Target Group: Forwards traffic to the ECS service based on health checks.

4. ECS Service: Manages the ECS tasks and ensures the desired count is maintained.

5. ECS Task Definition: Defines the container (image, CPU, memory, port) and logging configuration.

6. Security Group: Controls inbound/outbound traffic for the ECS tasks.

7. Subnets: Ensures ECS tasks are deployed in the specified VPC subnets.

8. CloudWatch Logs: Captures container logs for monitoring.

## Usage

```bash
terraform {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/ecs/monitoring"
}

dependency "networking" {
  config_path = "../networking"
}

dependency "cluster" {
  config_path = "../cluster-a"
}

inputs = {
  # Environment
  aws_account_id = "123456789012"
  aws_region     = "us-east-1"
  env            = "dev"

  # Networking
  vpc_id         = dependency.networking.outputs.vpc_id
  subnet_ids     = dependency.networking.outputs.private_subnet_ids
  alb_subnet_ids = dependency.networking.outputs.public_subnet_ids
  ecs_cluster_id = dependency.cluster.outputs.cluster_id

  # Grafana Configuration
  grafana_admin_password = "SecurePassword123!"  # Use AWS Secrets Manager in production
  grafana_domain         = "grafana-dev.automata-labs.nl"

  # Security - Restrict to your IP for production
  grafana_allowed_cidrs = ["0.0.0.0/0"]  # Change to ["YOUR_IP/32"] for production
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| aws_account_id | AWS account ID | string | - | yes |
| aws_region | AWS region | string | - | yes |
| env | Environment name | string | - | yes |
| vpc_id | VPC ID | string | - | yes |
| subnet_ids | Private subnet IDs for ECS tasks | list(string) | - | yes |
| alb_subnet_ids | Public subnet IDs for ALB | list(string) | - | yes |
| ecs_cluster_id | ECS cluster ID | string | - | yes |
| grafana_admin_password | Grafana admin password | string | - | yes |
| grafana_domain | Domain name for Grafana | string | - | yes |
| grafana_image | Grafana Docker image | string | `grafana/grafana:latest` | no |
| grafana_task_cpu | CPU units for task | string | `512` | no |
| grafana_task_memory | Memory for task (MiB) | string | `1024` | no |
| grafana_container_cpu | CPU units for container | number | `256` | no |
| grafana_container_memory | Memory for container (MiB) | number | `512` | no |
| grafana_desired_count | Number of Grafana tasks | number | `1` | no |
| grafana_admin_user | Grafana admin username | string | `admin` | no |
| grafana_allowed_cidrs | CIDRs allowed to access Grafana | list(string) | `["0.0.0.0/0"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| grafana_url | Full URL to access Grafana |
| grafana_alb_dns | ALB DNS name |
| grafana_alb_zone_id | ALB hosted zone ID |
| grafana_service_name | ECS service name |
| grafana_log_group | CloudWatch log group name |
| grafana_efs_id | EFS file system ID |

## Post-Deployment Setup

### 1. Access Grafana

After deployment completes, access Grafana at the URL from outputs:

```bash
terraform output grafana_url
# Output: http://dev-us-east-1-grafana-alb-123456789.us-east-1.elb.amazonaws.com
```

Login with:
- **Username**: `admin` (or your custom value)
- **Password**: The value you set for `grafana_admin_password`

### 2. Configure CloudWatch Datasource

The Grafana container comes with the CloudWatch plugin pre-installed. Add a datasource:

1. Navigate to **Configuration** → **Data Sources**
2. Click **Add data source**
3. Select **CloudWatch**
4. Configure:
   - **Name**: `CloudWatch`
   - **Authentication Provider**: `AWS SDK Default` (uses task IAM role)
   - **Default Region**: Your AWS region (e.g., `us-east-1`)
5. Click **Save & Test**

### 3. Import ECS Monitoring Dashboards

Import pre-built dashboards for ECS monitoring:

**Option 1: Use Verified Dashboard IDs**

1. Go to **Dashboards** → **Import**
2. Use these working dashboard IDs:
   - **11265** - ECS Cluster Monitoring (Container Insights)
   - **551** - AWS CloudWatch Browser

**Option 2: Create Custom ECS Dashboard**

If public dashboards don't work, create a custom dashboard:

1. Go to **Dashboards** → **New Dashboard**
2. Click **Add visualization**
3. Select your CloudWatch datasource
4. Add these useful queries:

**ECS Service CPU Usage:**
```yaml
Namespace: AWS/ECS
Metric: CPUUtilization
Dimensions:
  - ServiceName: your-service-name
  - ClusterName: your-cluster-name
```

**ECS Service Memory Usage:**
```yaml
Namespace: AWS/ECS
Metric: MemoryUtilization
Dimensions:
  - ServiceName: your-service-name
  - ClusterName: your-cluster-name
```

**Running Task Count:**
```yaml
Namespace: AWS/ECS
Metric: RunningTaskCount
Dimensions:
  - ServiceName: your-service-name
  - ClusterName: your-cluster-name
```

**ALB Response Time:**
```yaml
Namespace: AWS/ApplicationELB
Metric: TargetResponseTime
Dimensions:
  - LoadBalancer: app/your-alb-name/...
  - TargetGroup: targetgroup/your-tg-name/...
```

**ALB Request Count:**
```yaml
Namespace: AWS/ApplicationELB
Metric: RequestCount
Dimensions:
  - LoadBalancer: app/your-alb-name/...
```

**Option 3: Import from JSON**

Save this as a `.json` file and import it:

```json
{
  "dashboard": {
    "title": "ECS Service Monitoring",
    "panels": [
      {
        "title": "CPU Utilization",
        "type": "graph",
        "datasource": "CloudWatch",
        "targets": [
          {
            "namespace": "AWS/ECS",
            "metricName": "CPUUtilization",
            "dimensions": {
              "ServiceName": "$service",
              "ClusterName": "$cluster"
            },
            "statistics": ["Average"],
            "period": "300"
          }
        ]
      },
      {
        "title": "Memory Utilization",
        "type": "graph",
        "datasource": "CloudWatch",
        "targets": [
          {
            "namespace": "AWS/ECS",
            "metricName": "MemoryUtilization",
            "dimensions": {
              "ServiceName": "$service",
              "ClusterName": "$cluster"
            },
            "statistics": ["Average"],
            "period": "300"
          }
        ]
      }
    ],
    "templating": {
      "list": [
        {
          "name": "cluster",
          "type": "query",
          "datasource": "CloudWatch",
          "query": "dimension_values(AWS/ECS, CPUUtilization, ClusterName)"
        },
        {
          "name": "service",
          "type": "query",
          "datasource": "CloudWatch",
          "query": "dimension_values(AWS/ECS, CPUUtilization, ServiceName, {\"ClusterName\":\"$cluster\"})"
        }
      ]
    }
  }
}
```

Or create custom dashboards using CloudWatch metrics:
- `AWS/ECS` namespace for cluster/service metrics
- `AWS/ApplicationELB` for load balancer metrics
- `AWS/Logs` for log insights

### 4. Create Alerts (Optional)

Set up alerts for your ECS services:

1. Create a dashboard panel with a metric query
2. Click the panel → **Edit**
3. Go to **Alert** tab
4. Configure alert conditions (e.g., CPU > 80%)
5. Add notification channels (SNS, email, Slack)

## Security Considerations

### Production Deployment

For production environments, implement these security measures:

1. **Restrict Access**:
```hcl
grafana_allowed_cidrs = ["YOUR_CORPORATE_IP/32", "YOUR_VPN_IP/32"]
```

2. **Enable HTTPS**:
   - Add an ACM certificate to the ALB
   - Configure HTTPS listener
   - Redirect HTTP to HTTPS

3. **Strong Password**:
   - Use AWS Secrets Manager to generate and rotate passwords
   - Never commit passwords to version control

4. **Network Isolation**:
   - Keep Grafana in private subnets
   - Use internal ALB for corporate-only access
   - Implement VPN or bastion host access

5. **EFS Encryption**:
   - Already enabled with `encrypted = true`
   - Consider using KMS customer-managed keys

## Monitoring Your ECS Services

### Useful CloudWatch Metrics

Query these metrics in Grafana for comprehensive ECS monitoring:

**Cluster Metrics:**
- `CPUUtilization` - Cluster CPU usage
- `MemoryUtilization` - Cluster memory usage
- `RegisteredContainerInstancesCount` - Instance count

**Service Metrics:**
- `CPUUtilization` - Service CPU usage
- `MemoryUtilization` - Service memory usage
- `RunningTaskCount` - Number of running tasks
- `DesiredTaskCount` - Desired task count

**ALB Metrics:**
- `TargetResponseTime` - Response time
- `HTTPCode_Target_2XX_Count` - Successful requests
- `HTTPCode_Target_5XX_Count` - Server errors
- `HealthyHostCount` - Healthy targets
- `UnHealthyHostCount` - Unhealthy targets

### Example CloudWatch Query

```sql
fields @timestamp, @message
| filter @logStream like /grafana/
| sort @timestamp desc
| limit 20
```

## Troubleshooting

### Grafana Won't Start

Check CloudWatch logs:
```bash
aws logs tail /ecs/${env}/grafana --follow
```

Common issues:
- **EFS mount failure**: Check security groups allow port 2049
- **Password retrieval failure**: Verify IAM permissions for Secrets Manager
- **Memory issues**: Increase `grafana_task_memory` if needed

### Can't Access Grafana

1. Verify ALB health checks are passing:
```bash
aws elbv2 describe-target-health --target-group-arn <TG_ARN>
```

2. Check security group rules allow your IP
3. Verify tasks are running:
```bash
aws ecs describe-services --cluster <CLUSTER> --services <SERVICE>
```

### Data Not Showing

1. Verify CloudWatch datasource configuration
2. Check IAM role has CloudWatch read permissions
3. Ensure metrics exist in CloudWatch
4. Verify region matches where resources are deployed

## Cost Optimization

Estimated monthly costs (us-east-1):

- **ECS Fargate**: ~$15-20 (0.5 vCPU, 1GB RAM)
- **ALB**: ~$16-25
- **EFS**: ~$0.30/GB (first GB free)
- **CloudWatch Logs**: ~$0.50/GB ingested
- **Secrets Manager**: ~$0.40/secret/month

**Total**: ~$35-50/month for basic setup

To reduce costs:
- Use FARGATE_SPOT for non-critical environments
- Reduce log retention to 3-7 days
- Use EFS Infrequent Access for dashboards

## Upgrade and Maintenance

### Upgrade Grafana Version

Update the image version:
```hcl
grafana_image = "grafana/grafana:10.2.0"  # Specify version
```

Then apply:
```bash
terraform apply
```

ECS will perform a rolling update with zero downtime.

### Backup Dashboards

Dashboards are stored in EFS and persist across deployments. For additional backup:

1. Export dashboards from Grafana UI
2. Store JSON files in version control
3. Or use Grafana provisioning for dashboard-as-code
