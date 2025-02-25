# ------------------------------------------------------------------------
# These data sources fetch details about the EKS cluster, such as its endpoint, certificate authority, and authentication token.
# This information is required for the Helm provider to install the Load Balancer Controller in the cluster.
# ------------------------------------------------------------------------

data "aws_eks_cluster" "eks" {
  name = var.eks_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.eks_name
}

# ------------------------------------------------------------------------
# The helm provider is used to deploy the EKS Cluster Autoscaler into the Kubernetes cluster using a Helm chart.
# It authenticates to the cluster using the details fetched in the data sources.
# ------------------------------------------------------------------------

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_api_key
}

# ------------------------------------------------------------------------
# Deploy Grafana via Helm
# ------------------------------------------------------------------------

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "7.0.0"
  namespace  = "monitoring"
  create_namespace = true

  set {
    name  = "adminUser"
    value = "admin"
  }

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  # Adding toleration for CriticalAddonsOnly tainted nodes
  set {
    name  = "tolerations[0].key"
    value = "CriticalAddonsOnly"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }

  depends_on = [var.eks_node_group_general]
}

# ------------------------------------------------------------------------
# Deploy Prometheus via Helm
# ------------------------------------------------------------------------
# The Prometheus Helm chart is used to deploy the Prometheus monitoring system into the Kubernetes cluster.

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true

  values = [
    <<EOF
grafana:
  enabled: false  # Disable Grafana (we already installed it)

prometheus:
  prometheusSpec:
    scrapeInterval: "10s"  # Faster updates
    retention: "7d"        # Keep metrics for 7 days

kubeStateMetrics:
  enabled: true

nodeExporter:
  enabled: true

EOF
  ]

  # Adding toleration for CriticalAddonsOnly tainted nodes
  # TODO: validate pods placement of "node-exporter", "kube-state-metrics", and "prometheus-operator"
  #       and all monitoring pods in the managed node group
  set {
    name  = "tolerations[0].key"
    value = "CriticalAddonsOnly"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }

  depends_on = [var.eks_node_group_general]
}

# ------------------------------------------------------------------------
# EKS Cluster - Monitoring Grafana Dashboards
# ------------------------------------------------------------------------
# These resources deploy custom Grafana dashboards for monitoring the EKS cluster and the "Greeter" application.

# Shows real-time CPU, Memory, and Network stats per Pod & Namespace
resource "grafana_dashboard" "eks_metrics" {
  provider = grafana
  config_json = file("${path.module}/dashboards/eks-metrics.json")
}

# Shows HPA scaling behavior, replica counts, and response times
resource "grafana_dashboard" "hpa_monitoring" {
  provider = grafana
  config_json = file("${path.module}/dashboards/hpa-monitoring.json")
}

# Greeter App: Monitors API response times, request rates, and HTTP errors
resource "grafana_dashboard" "flask_performance" {
  provider = grafana
  config_json = file("${path.module}/dashboards/flask-performance.json")
}

# Monitors logs from the Loki log aggregation system
# Greeter App: Monitors logs from the Flask application
# resource "grafana_dashboard" "flask_logs" {
#   provider = grafana
#   config_json = file("${path.module}/dashboards/flask-logs.json")
# }

# TODO: Loki deployment on hold until troubleshooting installation issues with loki.yaml file provided
# Error: INSTALLATION FAILED: template: loki/templates/single-binary/statefulset.yaml:44:28: executing "loki/templates/single-binary/statefulset.yaml" at <include "loki.configMapOrSecretContentHash" (dict "ctx" . "name" "/config.yaml")>: error calling include: tem
# Manual installation through Helm also fails:

# kubectl create namespace loki
# helm repo add grafana https://grafana.github.io/helm-charts
# helm repo update
# helm install loki grafana/loki -f values/loki.yaml --namespace loki

# ------------------------------------------------------------------------
# Deploy Loki via Helm
# ------------------------------------------------------------------------
# The Loki Helm chart is used to deploy the Loki log aggregation system into the Kubernetes cluster.

# resource "helm_release" "loki" {
#   name       = "loki"
#   repository = "https://grafana.github.io/helm-charts"
#   chart      = "loki"
#   namespace  = "loki"
#   create_namespace = true

#   values = [file("${path.module}/values/loki.yaml")]

#   # Adding toleration for CriticalAddonsOnly tainted nodes
#   set {
#     name  = "tolerations[0].key"
#     value = "CriticalAddonsOnly"
#   }

#   set {
#     name  = "tolerations[0].operator"
#     value = "Exists"
#   }

#   depends_on = [var.eks_node_group_general]
# }

# ------------------------------------------------------------------------
# Deploy Promtail via Helm
# ------------------------------------------------------------------------
# Promtail will collect logs from all running pods and send them to Loki.

# resource "helm_release" "promtail" {
#   name       = "promtail"
#   repository = "https://grafana.github.io/helm-charts"
#   chart      = "promtail"
#   namespace  = "monitoring"

#   values = [
#     <<EOF
# config:
#   clients:
#     # When "Loki" service is running as ClusterIP
#     - url: http://localhost:3100/loki/api/v1/push
#     # When "Loki" service is running as LoadBalancer
#     # - url: http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push
#   snippets:
#     pipelineStages:
#       - docker: {}
# EOF
#   ]

#   # Adding toleration for CriticalAddonsOnly tainted nodes
#   set {
#     name  = "tolerations[0].key"
#     value = "CriticalAddonsOnly"
#   }

#   set {
#     name  = "tolerations[0].operator"
#     value = "Exists"
#   }

#   depends_on = [var.eks_node_group_general, helm_release.loki]
# }

# ------------------------------------------------------------------------
# Grafana Data Sources
# ------------------------------------------------------------------------
# These resources configure Grafana to use Prometheus and Loki as data sources for monitoring.

# # Adds Loki as a Data Source in Grafana
# resource "grafana_data_source" "loki" {
#   provider = grafana

#   type       = "loki"
#   name       = "Loki"
#   # url        = "http://loki.monitoring.svc.cluster.local:3100" # When "Loki" service is running as LoadBalancer
#   url        = "http://localhost:3100" # When "Loki" service is running as ClusterIP
#   is_default = false
# }
