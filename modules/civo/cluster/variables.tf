variable "civo_token" {
  description = "Civo API token for authentication"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Civo Kubernetes cluster"
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes Cluster version"
  type        = string
}

# CPU node pool configuration

variable "node_count" {
  description = "Number of nodes in the Civo Kubernetes cluster"
  type        = string
  default     = "0"

  validation {
    condition     = can(regex("^[0-9]+$", var.node_count))
    error_message = "node_count must be a non-negative integer string."
  }
}

variable "node_type" {
  description = "Type of nodes in the Civo Kubernetes cluster"
  type        = string
  default     = "g4s.kube.medium"
}

# GPU node pool configuration

variable "gpu_node_count" {
  description = "Number of GPU nodes in the Civo Kubernetes cluster"
  type        = string
  default     = "0"

  validation {
    condition     = can(regex("^[0-9]+$", var.gpu_node_count))
    error_message = "gpu_node_count must be a non-negative integer string."
  }
}

variable "gpu_node_type" {
  description = "Type of GPU nodes in the Civo Kubernetes cluster"
  type        = string
  default     = "g4g.kube.small"
}
