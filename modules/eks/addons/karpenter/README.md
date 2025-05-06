# Karpenter Module for Amazon EKS

This module provisions Karpenter within an existing EKS Cluster, allowing for dynamic and efficient node provisioning to meet workload demands.

## Overview

This repository contains Karpenter setup for auto-scaling nodes in an Amazon EKS cluster.

The configuration ensures **efficient node provisioning and cost optimization** by utilizing both **on-demand** and **spot instances**.

## Directory Structure

```ruby
karpenter/
├── manifests/
│   ├── node_pool.yaml          # Defines the Karpenter NodePool configuration
│   ├── node_class.yaml.tmpl    # Defines EC2NodeClass (formerly AWSNodeTemplate)
│   ├── inflate_deployment.yaml # Test deployment for Karpenter
├── main.tf                     # Terraform module for deploying Karpenter
├── variables.tf                # Input variables for customization
├── README.md                   # This documentation
```

## Key Features

- **Dynamic Node Provisioning:** Automatically scales nodes based on pending workloads.

- **Optimized Cost Management:** Utilizes a combination of on-demand and spot instances.

- **Efficient Pod Packing:** Ensures nodes are efficiently utilized, reducing waste.

- **Respects AWS vCPU Quotas:** Configured to prevent hitting quota limits and ensure uninterrupted scaling.

- **Flexible NodePool Configuration:** Supports instance size selection (medium, large) and various instance categories (c, m, t).


## Module Components

1. EKS Cluster Authentication & Helm Provider:

Uses `aws_eks_cluster` and `aws_eks_cluster_auth` data sources to fetch cluster details.

Configures `helm` and `kubectl` providers to interact with the EKS cluster.

2. Karpenter IAM and Permissions:

Uses `terraform-aws-modules/eks/aws//modules/karpenter` to configure necessary IAM roles.

Enables pod identity association.

Grants `AmazonSSMManagedInstanceCore` policy to the Karpenter node IAM role.

3. Karpenter Helm Deployment:

Deploys `Karpenter` using the `Helm` chart from the public Amazon ECR.

Ensures `CriticalAddonsOnly` taints are tolerated.

Integrates with the EKS cluster's endpoint and interruption queue.

4. Karpenter NodePool Configuration:

Defines which instances Karpenter can provision.

Uses `karpenter.k8s.aws/instance-category` to allow c, m, and t families.

Limits instance sizes to **medium** and **large**.

Supports **on-demand** and **spot** instances.

Configured to scale nodes incrementally with a maximum of **2 vCPUs and 4Gi memory per node**.

5. Karpenter `EC2NodeClass` (`AWSNodeTemplate`):

Defines which subnets and security groups Karpenter should use.

References the correct IAM role and applies necessary tags for discovery.

6. Inflate Deployment (Testing Deployment)

Provides an example deployment (inflate) to validate Karpenter's scaling behavior.

Uses the pause container image to simulate workloads without consuming resources.

## AWS vCPU Quotas & Scaling Limitations

### Default AWS vCPU Quotas

- AWS applies default vCPU quotas for each instance category (e.g.: 16 vCPUs for new accounts).

- If Karpenter hits this limit, new nodes may fail to launch with a VcpuLimitExceeded error.

### How to Increase AWS vCPU Quotas

- Go to the AWS Service Quotas page.

- Search for Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances.

- Click Request quota increase and specify a higher vCPU limit.

### Why Increase the vCPU Quota?

- Allows Karpenter to scale beyond the default 16 vCPU limit.

- Ensures higher replica counts can be scheduled without failures.

- Enables more efficient pod distribution across nodes, reducing bottlenecks.

## Caveats & Considerations

### Karpenter Pods

- Karpenter **deploys 2 pods by default** for high availability.

- Each node runs one Karpenter pod.

- If only one node is provisioned, the second pod will remain in a Pending state.

### Instance Selection

- By default, **small and medium instance sizes are prioritized** to improve bin-packing.

- If the cluster requires more vCPUs, consider adjusting NodePool limits to allow larger instances.

## Usage

1. Ensure your **EKS cluster** is running.
2. Provision `karpenter` module specifically through `Terragrunt`:

```bash
terragrunt apply
```

3. Or, provision `karpenter` module from the `root` (sandbox) directory:

```bash
./infrastructure-management apply
```

4. Verify that Karpenter is running:

```bash
kubectl get pods -n kube-system | grep karpenter
```

5. Test autoscaling by deploying the `inflate` workload:

```bash
kubectl scale deployment inflate --replicas=50
```

6. Check if new nodes are provisioned:

```bash
kubectl get nodes
```

7. Check `Karpenter` logs for more information in provisioning:

```bash
kubectl logs -f -n kube-system -l app.kubernetes.io/name=karpenter
```

## Best Practices

- **Use Mixed Instance Types**: Ensure your **NodePool** allows a variety of **instance families & sizes** to maximize availability.
- **Monitor Spot Instances**: AWS **can terminate spot instances** anytime—set a **fallback to on-demand nodes** to prevent disruptions.
- **Set Realistic Limits**: Reduce **NodePool CPU/memory limits** for **gradual scaling** instead of provisioning large nodes.
- **Enable Consolidation**: Use `WhenUnderutilized` consolidation to **reduce costs** by terminating underutilized nodes.

## Troubleshooting

### Karpenter is not provisioning nodes

**Check if pods are pending:**

```bash
kubectl get pods -A | grep Pending
```

**Check Karpenter logs:**

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter
```

### Some pods remain pending despite available nodes

- **Check instance-type requirements**: The `NodePool` might not match requested pod resources.
- **Check vCPU quotas**: You may be exceeding AWS vCPU limits.

### Nodes are not terminating after scaling down

- **Ensure consolidation is enabled** (`WhenUnderutilized` or `WhenEmpty`).
- **Check node taints**: Some system pods might prevent node termination.
