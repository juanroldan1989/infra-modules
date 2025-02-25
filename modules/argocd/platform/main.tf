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
# The helm provider is used to deploy the AWS Load Balancer Controller into the Kubernetes cluster using a Helm chart.
# It authenticates to the cluster using the details fetched in the data sources.
# ------------------------------------------------------------------------

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "4.5.2"

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  depends_on = [var.eks_node_group_general]
}
