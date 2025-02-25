provider "argocd" {
  server_addr = "localhost:8888" # kubectl port-forward service/argocd-server -n argocd 8888:443
  # username = (value set within env variable ARGOCD_AUTH_USERNAME)
  # password = (value set within env variable ARGOCD_AUTH_PASSWORD)
  # insecure = (value set within env variable ARGOCD_INSECURE)
  #            For testing purposes. Avoids "x509: certificate signed by unknown authority" error.
}

# Terraform resource for ArgoCD Application referencing Kubernetes manifests
resource "argocd_application" "k8s_app" {
  metadata {
    name      = var.argocd_application_name
    namespace = "argocd"
  }

  spec {
    project = var.project

    source {
      repo_url        = var.source_repo_url
      target_revision = var.source_target_revision
      path            = var.source_path # Path in the repo where the manifests are stored
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = var.destination_namespace
    }

    sync_policy {
      automated = {
        prune     = true
        self_heal = true
      }

      sync_options = ["Validate=false", "CreateNamespace=true"]
    }
  }
}

# Terraform resource for ArgoCD Application referencing a Helm chart

# # https://registry.terraform.io/providers/claranet/argocd/latest/docs/resources/application
# resource "argocd_application" "k8s-service-app" {
#   metadata {
#     name      = "k8s-service-app"
#     namespace = "argocd"
#   }

#   spec {
#     # A project is a logical grouping of applications
#     project = var.project

#     # TODO: generate Helm chart from Terraform "eks/internal-app" module
#     # TODO: name Helm chart "sisyphus_eks_application"
#     # TODO: upload Helm chart to Helm repository
#     # TODO: reference Helm chart in this resource
#     source {
#       repo_url        = var.source_repo_url # "https://some.chart.repo.io"
#       chart           = var.chart_name # "sisyphus_eks_application"
#       target_revision = var.source_target_revision # "1.2.3"

#       helm {
#         release_name = var.release_name # "testing"

#         parameter {
#           name  = var.image_tag_parameter_name # "image.tag"
#           value = var.image_tag_parameter_value # "1.2.3"
#         }

#         # HEML Chart Values to customize EKS Application resources (Deployment, HPA, Service, Ingress)
#         # EKS Application module: infrastructure/modules/eks/internal-app/main.tf
#         values = yamlencode({
#           eks_name          = var.eks_name
#           namespace         = var.namespace
#           app_name          = var.app_name
#           app_type          = var.app_type
#           health_check_path = var.health_check_path
#           ingress_prefix    = var.ingress_prefix
#           label             = var.label
#           docker_image      = var.docker_image
#           container_port    = var.container_port
#           replicas          = var.replicas
#         })
#       }
#     }

#     # Destination cluster and namespace where the application will be deployed
#     # Uself when we deploy multiple applications to different clusters
#     destination {
#       server    = "https://kubernetes.default.svc"
#       namespace = var.destination_namespace
#     }

#     sync_policy {
#       automated = {
#         prune     = true
#         self_heal = true
#       }

#       sync_options = ["Validate=false", "CreateNamespace=true"]
#     }
#   }
# }
