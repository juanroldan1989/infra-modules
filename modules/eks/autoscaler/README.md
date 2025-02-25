# EKS - Cluster Autoscaler module

- This Terraform module deploys the `Kubernetes Cluster Autoscaler` on an `AWS EKS` cluster using Helm.

- The Cluster Autoscaler automatically adjusts the `number of nodes` in our cluster based on the current workload, optimizing resource usage and cost efficiency.

## Features

- Deploys the Kubernetes Cluster Autoscaler via Helm.

- Configures `IAM roles and policies` for Autoscaler authentication.

- Uses `AWS EKS Pod Identity` Association to manage permissions securely.

- Supports `auto-discovery` of node groups for efficient scaling.

## Resources Created

This module provisions the following AWS resources:

1. **IAM Role**: Grants necessary permissions to the Cluster Autoscaler.
2. **IAM Policy**: Defines permissions for interacting with AWS Auto Scaling and EC2 services.
3. **IAM Role Policy Attachment**: Binds the IAM policy to the IAM role.
4. **EKS Pod Identity Association**: Associates the IAM role with the Cluster Autoscaler service account.
5. **Helm Release**: Installs the Cluster Autoscaler into the EKS cluster.

## Dependencies

This module requires:

- An existing `EKS` cluster.

- `AWS IAM` permissions to create roles, policies, and pod identity associations.

- The `Helm` provider must be configured with access to the Kubernetes API.

- `Metrics Server` must be installed (metrics_server dependency) for autoscaler metrics.
