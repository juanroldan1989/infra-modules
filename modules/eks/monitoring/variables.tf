# ------------------------------------------------------------------------
# EKS VARIABLES
# ------------------------------------------------------------------------

variable "eks_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
}

variable "eks_node_group_general" {
  description = "Reference to the general EKS node group"
  type        = any
}

# ------------------------------------------------------------------------
# GRAFANA VARIABLES
# ------------------------------------------------------------------------

variable "grafana_url" {
  description = "The URL of the Grafana instance"
  type        = string
  default     = "http://grafana.monitoring.svc.cluster.local" # When "Grafana" service is running as LoadBalancer
  # default     = "http://localhost:3000" # When "Grafana" service is running as ClusterIP
}

# TODO: Automate the creation of the API key during module provisioning
#       This API Key is needed for the Grafana provider to interact with the Grafana API
#       and create dashboards and data sources
variable "grafana_api_key" {
  description = "API key for Grafana authentication"
  type        = string
  sensitive   = true
}
