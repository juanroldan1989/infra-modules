# Namespace Module

This Terraform module creates a `Kubernetes` namespace in an Amazon EKS cluster.

It retrieves the necessary cluster information and configures the Kubernetes provider with secure authentication and connection details before creating the namespace.

## Overview

This module:

1. Retrieves EKS Cluster Information:

- Utilizes `aws_eks_cluster` data source to get details such as the `cluster endpoint` and `certificate`.
- Uses `aws_eks_cluster_auth` data source to generate a `token` for authentication.

2. Configures the Kubernetes Provider:

- The EKS cluster `endpoint`, `certificate` and `token` are applied to the Kubernetes provider for secure communication.

3. Creates a Kubernetes Namespace:

- Defines a kubernetes_namespace resource with a name defined by a user-provided variable.

## Providers

The module uses the following providers:

1. AWS Provider for:

- `aws_eks_cluster` data source
- `aws_eks_cluster_auth` data source

2. Kubernetes Provider for:

- Managing resources in the `EKS` cluster (e.g., creating namespaces)
