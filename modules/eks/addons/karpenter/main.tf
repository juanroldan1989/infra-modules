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
  load_config_file       = var.use_local_kubeconfig
  host                   = var.use_local_kubeconfig ? null : data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = var.use_local_kubeconfig ? null : base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = var.use_local_kubeconfig ? null : data.aws_eks_cluster_auth.eks.token
}

# ------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------

data "aws_ecrpublic_authorization_token" "token" {}

# ------------------------------------------------------------------------
# Karpenter AWS Resources
# ------------------------------------------------------------------------

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.35.0" # Always use modules with versions to match AWS provider requirements: https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v20.35.0/modules/karpenter#requirements

  cluster_name = var.eks_name

  enable_v1_permissions = true

  enable_pod_identity             = true
  create_pod_identity_association = true

  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

# ------------------------------------------------------------------------
# Karpenter Helm Chart
# ------------------------------------------------------------------------

resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.0.0"
  wait                = false

  values = [
    <<-EOT
    serviceAccount:
      name: ${module.karpenter.service_account}
    settings:
      clusterName: ${var.eks_name}
      clusterEndpoint: ${data.aws_eks_cluster.eks.endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
      podTolerations: # Ensure Karpenter pod themselves tolerate CriticalAddonsOnly taint in nodes
        - key: "CriticalAddonsOnly"
          operator: "Exists"
    EOT
  ]

  depends_on = [var.eks_name]  # Ensures Helm runs only if EKS exists
}

# ------------------------------------------------------------------------
# Karpenter NodePool (previously known as Provisioner)
# Defines what kind of nodes Karpenter can create
# There can be multiple NodePools with different requirements and limits per Karpenter installation
# Example: https://www.qovery.com/blog/configuring-kubernetes-karpenter-lessons-learned-from-our-experience/
# ------------------------------------------------------------------------

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = file("${path.module}/manifests/node_pool.yaml")

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

# ------------------------------------------------------------------------
# Karpenter EC2NodeClass (previously known as AWSNodeTemplate)
# ------------------------------------------------------------------------

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = templatefile("${path.module}/manifests/node_class.yaml.tmpl", {
    role_name: module.karpenter.node_iam_role_name,
    eks_name: var.eks_name
  })

  depends_on = [
    helm_release.karpenter
  ]
}

# ------------------------------------------------------------------------
# Inflate deployment: Example deployment to test Karpenter
# ------------------------------------------------------------------------

resource "kubectl_manifest" "karpenter_example_deployment" {
  yaml_body = file("${path.module}/manifests/inflate_deployment.yaml")

  depends_on = [
    helm_release.karpenter
  ]
}

# ------------------------------------------------------------------------
# Kubernetes Dashboard
# TODO: validate setup and easy access to the dashboard
# ------------------------------------------------------------------------

# resource "helm_release" "kubernetes_dashboard" {
#   namespace           = "kubernetes-dashboard"
#   name                = "kubernetes-dashboard"
#   repository          = "https://kubernetes.github.io/dashboard"
#   chart               = "kubernetes-dashboard"
#   version             = "5.0.0"
#   wait                = false
#   create_namespace    = true
#   timeout             = 300

#   values = [
#     <<-EOT
#     serviceAccount:
#       name: ${var.eks_name}-kubernetes-dashboard
#     EOT
#   ]
# }

# resource "kubectl_manifest" "kubernetes_dashboard_service_account" {
#   yaml_body = <<-YAML
#     apiVersion: v1
#     kind: ServiceAccount
#     metadata:
#       name: ${var.eks_name}-kubernetes-dashboard
#       namespace: kubernetes-dashboard
#   YAML

#   depends_on = [
#     helm_release.kubernetes_dashboard
#   ]
# }

# resource "kubectl_manifest" "kubernetes_dashboard_cluster_role_binding" {
#   yaml_body = <<-YAML
#     apiVersion: rbac.authorization.k8s.io/v1
#     kind: ClusterRoleBinding
#     metadata:
#       name: ${var.eks_name}-kubernetes-dashboard-admin-binding
#     roleRef:
#       apiGroup: rbac.authorization.k8s.io
#       kind: ClusterRole
#       name: cluster-admin
#     subjects:
#       - kind: ServiceAccount
#         name: ${var.eks_name}-kubernetes-dashboard-admin
#         namespace: kubernetes-dashboard
#   YAML

#   depends_on = [
#     kubectl_manifest.kubernetes_dashboard_service_account
#   ]
# }

# resource "kubectl_manifest" "kubernetes_dashboard_sa_secret" {
#   yaml_body = <<-YAML
#     apiVersion: v1
#     kind: Secret
#     metadata:
#       name: kubernetes-dashboard-admin-token
#       namespace: kubernetes-dashboard
#       annotations:
#         kubernetes.io/service-account.name: ${var.eks_name}-kubernetes-dashboard-admin
#     type: kubernetes.io/service-account-token
#   YAML

#   depends_on = [
#     kubectl_manifest.kubernetes_dashboard_service_account
#   ]
# }
