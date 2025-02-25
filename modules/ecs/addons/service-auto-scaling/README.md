# ECS Auto Scaling Terraform Module

This Terraform module provides resources to set up automatic scaling for an ECS service including:

- IAM roles
- CloudWatch alarms
- Scaling policies for both scaling up and down based on CPU utilization.

## Features

- **IAM Role for Auto Scaling**: Creates an IAM role with the necessary permissions for ECS auto-scaling.
- **Auto Scaling Target**: Defines the ECS service target for auto-scaling.
- **Scaling Policies**:
  - **Scale Up**: Increases the desired task count by one when CPU utilization exceeds a threshold.
  - **Scale Down**: Decreases the desired task count by one when CPU utilization is below a threshold.
- **CloudWatch Alarms**: Monitors ECS service CPU utilization and triggers scaling actions based on predefined thresholds.

## Resources

The module creates the following resources:

1. **IAM Role and Policy Attachment**:
   - `aws_iam_role`: ECS auto-scaling role.
   - `aws_iam_role_policy_attachment`: Attaches the Amazon ECS Auto Scaling policy.

2. **App Auto Scaling**:
   - `aws_appautoscaling_target`: Defines the ECS service as a scalable target.
   - `aws_appautoscaling_policy`: Configures policies for scaling up and down.

3. **CloudWatch Alarms**:
   - `aws_cloudwatch_metric_alarm`: Alarms to trigger scaling up/down based on CPU utilization thresholds.

## Usage

```hcl
module "ecs_auto_scaling" {
  source                  = "path/to/this/module"
  ecs_cluster_name        = "your-ecs-cluster-name"
  ecs_service_name        = "your-ecs-service-name"
  ecs_auto_scale_role_name = "ecs-auto-scale-role"
}
```
