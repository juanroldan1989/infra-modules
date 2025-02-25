# ------------------------------------------------------------------------
# VARIABLES FOR ARGCOD APPLICATION
# ------------------------------------------------------------------------

variable "project" {
  description = "Project name"
  type        = string
  default     = "default"
}

variable "argocd_application_name" {
  description = "The name of the ArgoCD application"
  type        = string
}

variable "source_repo_url" {
  description = "The URL of the source repository"
  type        = string
  default     = "https://github.com/juanroldan1989/sisyphus.git"
}

variable "source_path" {
  description = "The path to the source directory"
  type        = string
  default     = "infrastructure/modules/eks/internal-app" # validate application format (.tf or .yaml)
}

variable "source_target_revision" {
  description = "The target revision of the source repository"
  type        = string
  default     = "HEAD"
}

variable "destination_namespace" {
  description = "The namespace where the application will be deployed"
  type        = string
  default     = "argocd-apps"
}

# ------------------------------------------------------------------------
# VARIABLES FOR EKS APPLICATION
# ------------------------------------------------------------------------

variable "namespace" {
  type = string
}

variable "app_name" {
  type = string
}

variable "app_type" {
  type    = string
  default = "internal" # `internal` or `internet-facing`
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "ingress_prefix" {
  type    = string
  default = "/app"
}

variable "label" {
  type = string
}

variable "docker_image" {
  type    = string
  default = "k8s.gcr.io/echoserver:1.4"
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "replicas" {
  type    = number
  default = 1
}
