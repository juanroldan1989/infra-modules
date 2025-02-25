# ------------------------------------------------------------------------
# Retrieves information about the specified EKS cluster by name.
# This is used to configure the Kubernetes provider with the cluster's endpoint and certificate.
# ------------------------------------------------------------------------

data "aws_eks_cluster" "default" {
  name = var.eks_name
}

# ------------------------------------------------------------------------
# Retrieves authentication details for the specified EKS cluster by name.
# This is used to generate a token to authenticate with the cluster.
# ------------------------------------------------------------------------

data "aws_eks_cluster_auth" "default" {
  name = var.eks_name
}

# ------------------------------------------------------------------------
# Configures the Kubernetes provider to interact with the EKS cluster.
# - `host`: Specifies the EKS cluster endpoint.
# - `cluster_ca_certificate`: Uses the cluster's certificate for secure communication.
# - `token`: Authenticates the provider with the cluster using the token generated from the EKS cluster authentication data source.
# ------------------------------------------------------------------------

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token

  # Configures an alternative authentication mechanism using AWS CLI.
  # This is helpful for dynamic authentication workflows where the AWS CLI is used to obtain a token.
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id]
    command     = "aws"
  }
}

# ------------------------------------------------------------------------
# Creates a Kubernetes Deployment in the specified EKS cluster and Namespace
# ------------------------------------------------------------------------

resource "kubernetes_deployment" "deployment" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      App = var.label
    }
  }

  spec {
    selector {
      match_labels = {
        App = var.label
      }
    }
    template {
      metadata {
        labels = {
          App = var.label
        }
      }
      spec {
        container {
          image = var.docker_image
          name  = var.app_name

          port {
            container_port = var.container_port
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }

  # Ensure HPA is deleted first before deleting the Deployment
  depends_on = [kubernetes_horizontal_pod_autoscaler_v1.example]
}

# ------------------------------------------------------------------------
# Creates a Kubernetes Horizontal Pod Autoscaler in the specified EKS cluster and Namespace
# ------------------------------------------------------------------------

resource "kubernetes_horizontal_pod_autoscaler_v1" "example" {
  metadata {
    name = var.app_name
    namespace = var.namespace
  }

  spec {
    max_replicas = 10
    min_replicas = var.replicas

    # TODO: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/horizontal_pod_autoscaler_v2beta2#nestedblock--spec--behavior
    # behavior {
    #   scale_down {
    #     stabilization_window_seconds = 180 # Default is 300 seconds
    #   }
    # }

    target_cpu_utilization_percentage = 80

    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = var.app_name
    }
  }
}

# ------------------------------------------------------------------------
# Creates a Kubernetes Service in the specified EKS cluster and Namespace
# ------------------------------------------------------------------------

resource "kubernetes_service" "service" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
  }

  spec {
    selector = {
      App = kubernetes_deployment.deployment.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = var.container_port
      target_port = var.container_port
    }

    type = "ClusterIP"
  }
}

# ------------------------------------------------------------------------
# Creates a Kubernetes Ingress in the specified EKS cluster and Namespace
# ------------------------------------------------------------------------

resource "kubernetes_ingress_v1" "ingress" {
  wait_for_load_balancer = true

  metadata {
    name      = var.app_name
    namespace = var.namespace
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = var.health_check_path
    }
  }

  spec {
    ingress_class_name = "alb"

    default_backend {
      service {
        name = kubernetes_service.service.metadata.0.name
        port {
          number = kubernetes_service.service.spec.0.port.0.port
        }
      }
    }

    rule {
      http {
        path {
          backend {
            service {
              name = kubernetes_service.service.metadata.0.name
              port {
                number = kubernetes_service.service.spec.0.port.0.port
              }
            }
          }
          path      = var.ingress_prefix
          path_type = "Prefix"
        }
      }
    }
  }
}
