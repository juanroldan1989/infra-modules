# ------------------------------------------------------------------------
# This data block fetches information about the specified EKS cluster, including
# endpoint and certificate details. It is used to configure the Kubernetes provider.
# ------------------------------------------------------------------------

data "aws_eks_cluster" "eks" {
  name = var.eks_name
}

# ------------------------------------------------------------------------
# This data block retrieves authentication details for the specified EKS cluster,
# such as the token required for accessing the cluster.
# ------------------------------------------------------------------------

data "aws_eks_cluster_auth" "eks" {
  name = var.eks_name
}

# ------------------------------------------------------------------------
# This provider block configures the Helm provider to interact with the EKS cluster.
# It uses the cluster's endpoint, CA certificate, and authentication token to establish
# communication with Kubernetes.
# ------------------------------------------------------------------------

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

# ------------------------------------------------------------------------
# Configures the Kubernetes provider to interact with the EKS cluster.
# - `host`: Specifies the EKS cluster endpoint.
# - `cluster_ca_certificate`: Uses the cluster's certificate for secure communication.
# - `token`: Authenticates the provider with the cluster using the token generated from the EKS cluster authentication data source.
# ------------------------------------------------------------------------

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token

  # Configures an alternative authentication mechanism using AWS CLI.
  # This is helpful for dynamic authentication workflows where the AWS CLI is used to obtain a token.
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.eks.id]
    command     = "aws"
  }
}

# ------------------------------------------------------------------------
# This resource deploys the Metrics Server using a Helm chart. The Metrics Server
# provides resource utilization metrics, such as CPU and memory usage, for Kubernetes
# workloads. It is installed in the kube-system namespace.
# ------------------------------------------------------------------------

resource "helm_release" "metrics_server" {
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.1"

  # The values file allows for customizing the Helm chart deployment configuration.
  values = [file("${path.module}/values/metrics-server.yaml")]

  depends_on = [var.eks_node_group_general]
}

# ------------------------------------------------------------------------
# RoleBinding for HPA to allow it to fetch metrics from Metrics Server
# It binds the system:aggregated-metrics-reader ClusterRole to
# the horizontal-pod-autoscaler ServiceAccount in the kube-system namespace.
# ------------------------------------------------------------------------

resource "kubernetes_role_binding" "hpa_metrics_reader" {
  metadata {
    name      = "hpa-metrics-reader"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:aggregated-metrics-reader"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "horizontal-pod-autoscaler"
    namespace = "kube-system"
  }

  depends_on = [helm_release.metrics_server]
}
