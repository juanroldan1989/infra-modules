# EKS Load Balancer Controller module

This module sets up `AWS Load Balancer Controller` in EKS cluster. It handles:

- Fetching cluster details for authentication.
- Configuring `IAM` roles and policies for secure `AWS` resource management by the controller.
- Deploying the `Helm` chart to install the controller into the `kube-system` namespace.

This way, the EKS cluster can automatically manage `ALBs/NLBs` for Kubernetes resources like `Ingress` and `Services` with minimal manual effort.
