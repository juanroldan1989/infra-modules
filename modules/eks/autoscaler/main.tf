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

# ------------------------------------------------------------------------
# IAM Role for Cluster Autoscaler
# This role allows the Cluster Autoscaler service to assume a role and manage auto-scaling resources.
# ------------------------------------------------------------------------

resource "aws_iam_role" "cluster_autoscaler" {
  name = "${var.eks_name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------
# IAM Policy for Cluster Autoscaler
# This policy grants permissions needed for Cluster Autoscaler to interact
# with AWS Auto Scaling and EC2 services.
# ------------------------------------------------------------------------

resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${var.eks_name}-cluster-autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      },
    ]
  })
}

# ------------------------------------------------------------------------
# Attach IAM Policy to the IAM Role
# This ensures that the Cluster Autoscaler role has the necessary permissions.
# ------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

# ------------------------------------------------------------------------
# Associate IAM Role with Kubernetes Service Account
# This allows the Kubernetes service account to assume the IAM role and use AWS permissions.
# ------------------------------------------------------------------------

resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = var.eks_name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler.arn
}

# ------------------------------------------------------------------------
# Install Cluster Autoscaler via Helm
# This deploys the Cluster Autoscaler in the Kubernetes cluster using a Helm chart.
# ------------------------------------------------------------------------

resource "helm_release" "cluster_autoscaler" {
  name = "autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.37.0"

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = var.eks_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name = "extraArgs.nodes"
    value = "1:5"
  }

  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
  }

  set {
    name  = "extraArgs.scale-down-enabled"
    value = "true"
  }

  set {
    name  = "extraArgs.scale-down-utilization-threshold"
    value = "0.3"
  }

  depends_on = [var.metrics_server]
}
