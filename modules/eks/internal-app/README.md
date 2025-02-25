# EKS Internal Application Module

## Introduction

This Terraform module automates the deployment of **internal** applications within an Amazon EKS cluster using Kubernetes resources.

It sets up a Kubernetes `Deployment`, `Service` and `Horizontal Pod Autoscaler` (HPA) to manage and scale workloads efficiently.

The module integrates seamlessly with an existing `EKS` cluster.

## Resources Created

This module creates the following resources:

- **Kubernetes Deployment**: Deploys an application container with specified resource limits and requests.

- **Kubernetes Service**: Exposes the application within the cluster using ClusterIP.

- **Kubernetes Provider Configuration**: Uses authentication tokens to interact with the EKS cluster.

- **Kubernetes Horizontal Pod Autoscaler (HPA):** Automatically scales pods based on `CPU` utilization.

### Kubernetes Horizontal Pod Autoscaler (HPA)

- HPA is a form of autoscaling that **increases or decreases the number of pods** in a replication controller, deployment, replica set, or stateful set based on `CPU` utilization.

- The scaling is horizontal because it affects **the number of instances** rather than the resources allocated to a single container.

- `HPA` can make scaling decisions based on custom or externally provided metrics and works automatically after initial configuration. All you need to do is define the `MIN` and `MAX` number of replicas.

- Once configured, the `Horizontal Pod Autoscaler` controller is in charge of checking the metrics and then scaling your replicas up or down accordingly. By default, HPA checks metrics every `15` seconds.

<img src="https://github.com/MMOX-Engineering/multi-cloud-infra/blob/main/screenshots/hpa-autoscaling.png">

- More detailed view:

<img src="https://github.com/MMOX-Engineering/multi-cloud-infra/blob/main/screenshots/hpa-overview.png">

### Pros of Reducing the Scale-Down Window (180s or less)

```bash
resource "kubernetes_horizontal_pod_autoscaler_v2" "example" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
  }

  spec {
    max_replicas = 10
    min_replicas = var.replicas

    behavior {
      scale_down {
        stabilization_window_seconds = 180 # Change to 3 minutes instead of 5
      }
    }

    target_cpu_utilization_percentage = 80

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = var.app_name
    }
  }
}
```

1️⃣ Faster Resource Optimization

- Lower cost in bursty workloads: If your traffic has short spikes, reducing the scale-down time ensures unused pods terminate quickly, reducing cloud costs.
- Less wasted compute: Unused pods won’t sit idle for too long before being removed.

2️⃣ More Responsive Scaling for Dynamic Workloads

- Ideal for applications with short-lived spikes in demand.
- Prevents unnecessary over-provisioning when load drops quickly.

3️⃣ Faster Node Termination with Karpenter

- If Karpenter is provisioning nodes dynamically, reducing the window ensures that nodes with underutilized pods can scale down faster, freeing up resources.

### Cons of Reducing the Scale-Down Window

1️⃣ Risk of Premature Scaling Down

- If traffic temporarily drops, but spikes again shortly after, Kubernetes might remove pods too aggressively, causing:

1. Increased cold starts (slower response times when load returns).
2. Unnecessary pod churn, where pods keep getting created/destroyed.
3. Load balancing instability, with ALB/Nginx re-routing frequently.

2️⃣ Higher Deployment Overhead

- Spinning up new pods adds startup time (e.g., pulling container images, initializing DB connections, warming caches).
- If your app has a slow startup time, scaling down too fast might hurt responsiveness when traffic returns.

3️⃣ Potential Impact on Multi-Service Dependencies

- If your services rely on each other (e.g., greeter -> greeting -> name), fast scale-down could remove pods before dependent services stabilize, causing unexpected failures.

### Good use cases for lower values (180s or less):

- Stateless workloads (like HTTP APIs) with fast startup times.
- Cost-sensitive environments with pay-as-you-go pricing.
- Highly bursty traffic (e.g., e-commerce sites during flash sales).

### Not recommended for:

- Stateful applications (databases, long-lived processes).
- Apps with long startup times (e.g., Java apps, machine learning models).
- Critical workloads requiring high availability at all times.

## Dependencies

This module depends on the following:

- An existing Amazon `EKS` cluster.

- AWS `IAM` permissions to manage Kubernetes resources.

- Kubernetes `metrics server` for `HPA` functionality.
