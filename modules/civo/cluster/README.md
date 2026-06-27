# Civo Kubernetes Cluster Terraform Module

## Introduction

This Terraform module provisions a Civo Kubernetes workload cluster and registers it with the management cluster so Argo CD can deploy applications to it through GitOps.

The module supports CPU-only, GPU-only, and mixed CPU/GPU node pool layouts. GPU node pools should use Kubernetes-compatible Civo size names, which include the `.kube.` suffix.

## Features

- Creates an isolated Civo network for the cluster.
- Creates a dedicated Civo firewall with HTTP, HTTPS, Kubernetes API, SSH, and outbound rules.
- Provisions a Civo Kubernetes cluster with dynamic CPU and GPU node pools.
- Supports GPU node pools for LLM, AI, and ML workloads.
- Registers the workload cluster in Argo CD using a Kubernetes Secret.
- Labels GPU-capable Argo CD clusters with `gpu=true` when `gpu_node_count` is greater than zero.
- Stores the raw kubeconfig in the management cluster for administrative access.
- Copies AWS credentials into the workload cluster for External Secrets Operator.
- Validates node counts and requires at least one CPU or GPU node.

## Resources Created

| Resource | Purpose |
| --- | --- |
| `civo_network.cluster` | Dedicated Civo network for the Kubernetes cluster. |
| `civo_firewall.cluster` | Firewall rules for ingress, Kubernetes API access, SSH, and egress. |
| `civo_kubernetes_cluster.cluster` | Managed Civo Kubernetes cluster with CPU and/or GPU node pools. |
| `kubernetes_secret_v1.argocd_cluster_secret` | Argo CD cluster registration Secret in the management cluster, including workload and optional GPU labels. |
| `kubernetes_secret_v1.cluster_secret` | Raw kubeconfig Secret for later administrative access. |
| `kubernetes_namespace_v1.external_secrets` | `external-secrets` namespace in the workload cluster. |
| `kubernetes_secret_v1.aws_creds` | AWS credentials copied into the workload cluster for ESO. |

## Usage

```hcl
module "civo_cluster" {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/civo/cluster?ref=main"

  civo_token      = var.civo_token
  cluster_name    = "london"
  k8s_version     = "1.35.0-k3s1"
  node_count      = "0"
  node_type       = "g4s.kube.large"
  gpu_node_count  = "1"
  gpu_node_type   = "g4g.kube.small"
}
```

### Argo CD Cluster Labels

The module registers each workload cluster in Argo CD using a cluster Secret. The Secret always receives these labels:

```yaml
argocd.argoproj.io/secret-type: cluster
workload: "true"
cluster: <cluster_name>
```

When `gpu_node_count` is greater than zero, the module also adds:

```yaml
gpu: "true"
```

The platform repository can use this label to target GPU-only add-ons, such as the NVIDIA GPU Operator, through an Argo CD ApplicationSet selector:

```yaml
matchLabels:
  workload: "true"
  gpu: "true"
```

### Find Selectable GPU Sizes

Use the Civo sizes API to confirm the available Kubernetes GPU node types for the target region/account.

```bash
curl -H "Authorization: bearer ${CIVO_TOKEN}" https://api.civo.com/v2/sizes | jq
```

Example response fragment:

```json
{
  "type": "Kubernetes",
  "name": "an.g1.l40s.kube.x1",
  "nice_name": "Small - Nvidia L40S 40GB",
  "cpu_cores": 12,
  "gpu_count": 1,
  "gpu_type": "nvidia.com/AD102GL_L40S",
  "ram_mb": 98304,
  "disk_gb": 200,
  "transfer_tb": 12,
  "description": "Small - Nvidia L40S 40GB",
  "hugepages": 0,
  "selectable": true
}
```

Instance sizes can appear without the Kubernetes suffix:

```json
{
  "type": "Instance",
  "name": "an.g1.l40s.x1",
  "nice_name": "Small - Nvidia L40S 40GB",
  "cpu_cores": 12,
  "gpu_count": 1,
  "gpu_type": "nvidia.com/AD102GL_L40S",
  "ram_mb": 98304,
  "disk_gb": 200,
  "transfer_tb": 12,
  "description": "Small - Nvidia L40S 40GB",
  "hugepages": 0,
  "selectable": true
}
```

For Kubernetes node pools, use the size name that contains the `.kube.` suffix.

### GPU Node Pool Options

The following GPU options are available examples for Kubernetes node pools.

Source: <https://dashboard.civo.com/instances/new>

#### `g4g.kube.small` - Nvidia A100 80GB

```text
CPU Cores     - 12
RAM           - 96 GB
GPU           - 1 x Nvidia A100 80GB
NVMe storage  - 200 GB
Data transfer - FREE

$1.790000 per hr
```

#### `g4g.kube.medium` - Nvidia A100 80GB

```text
CPU Cores     - 24
RAM           - 192 GB
GPU           - 2 x Nvidia A100 80GB
NVMe storage  - 400 GB
Data transfer - FREE

$3.580000 per hr
```

## Outputs

| Output | Description | Sensitive |
| --- | --- | --- |
| `raw_kubeconfig` | Raw kubeconfig returned by the Civo Kubernetes cluster resource. | Yes |

## Dependencies

| Dependency | Version | Purpose |
| --- | --- | --- |
| Terraform | `>= 1.2` recommended | Required for resource preconditions and modern module behavior. |
| `civo/civo` provider | `1.1.0` | Creates Civo network, firewall, and Kubernetes cluster resources. |
| `hashicorp/kubernetes` provider | `2.23.0` | Creates Kubernetes resources in the management and workload clusters. |
| `hashicorp/http` provider | Latest | Detects the management cluster public IP for firewall rules. |
| Argo CD namespace | Existing | Receives the workload cluster registration Secret. |
| `aws-creds` Secret | Existing | Source Secret copied from the management cluster into the workload cluster. |

## Diagram

```text
                          +--------------------------+
                          | Management Kubernetes    |
                          | Cluster                  |
                          |                          |
                          |  - Argo CD               |
                          |  - Crossplane Terraform  |
                          |  - aws-creds Secret      |
                          +------------+-------------+
                                       |
                                       | Terraform Workspace
                                       v
+----------------------+      +--------+---------+      +----------------------+
| Civo Network         |<-----| Civo Firewall    |----->| Civo Kubernetes     |
| cluster network      |      | 80/443/6443/22   |      | Workload Cluster    |
+----------------------+      +------------------+      +----------+-----------+
                                                                  |
                                     +----------------------------+----------------------------+
                                     |                                                         |
                                     v                                                         v
                           +---------+----------+                                  +-----------+---------+
                           | CPU Node Pool      |                                  | GPU Node Pool       |
                           | optional           |                                  | optional            |
                           +--------------------+                                  +---------------------+
                                                                  |
                                                                  v
                                                   +--------------+---------------+
                                                   | Workload Cluster Bootstrap  |
                                                   | - external-secrets ns       |
                                                   | - aws-creds Secret          |
                                                   +------------------------------+

Management cluster outputs:

  Argo CD cluster Secret  --->  registers workload cluster
                           --->  adds gpu=true when gpu_node_count > 0
  Kubeconfig Secret       --->  stores raw kubeconfig for admin use
```
