# ------------------------------------------------------------------------
# VARIABLES FOR EKS CLUSTER
# ------------------------------------------------------------------------

variable "eks_name" {
  description = "The name of the EKS cluster."
  type        = string
}

# ------------------------------------------------------------------------
# VARIABLES FOR APPLICATION
# ------------------------------------------------------------------------

variable "namespace" {
  type = string
}

variable "app_name" {
  type = string
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
