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

data "aws_iam_policy_document" "aws_lbc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# ------------------------------------------------------------------------
# Creates an IAM role that the AWS Load Balancer Controller pod will assume using IRSA (IAM Roles for Service Accounts).
# The role allows the pod to perform actions such as creating and managing AWS Load Balancers.
# ------------------------------------------------------------------------

resource "aws_iam_role" "aws_lbc" {
  name               = "${var.eks_name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
}

# ------------------------------------------------------------------------
# Attaches a predefined IAM policy (e.g., from a file) to the role.
# This policy grants specific permissions required by the controller,
# such as managing load balancers and related AWS resources.
# ------------------------------------------------------------------------

resource "aws_iam_policy" "aws_lbc" {
  policy = file("${path.module}/iam/AWSLoadBalancerController.json")
  name   = "AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name
}

# ------------------------------------------------------------------------
# Links the IAM role to the Kubernetes service account in the kube-system namespace using IRSA.
# This allows the AWS Load Balancer Controller pod to assume the IAM role and interact with AWS services securely.
# ------------------------------------------------------------------------

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = var.eks_name
  namespace       = "kube-system"
  service_account = "${var.env}-aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc.arn
}

# ------------------------------------------------------------------------
# Deploys the AWS Load Balancer Controller Helm chart into the Kubernetes cluster.
# Configures the clusterName and links the Helm chart with the service account created for the controller.
# ------------------------------------------------------------------------

resource "helm_release" "aws_lbc" {
  name = "${var.env}-aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.0"

  set {
    name  = "clusterName"
    value = var.eks_name
  }

  set {
    name  = "serviceAccount.name"
    value = "${var.env}-aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "extraArgs"
    value = "--aws-region=${var.aws_region} --aws-vpc-id=${var.vpc_id}"
  }

  # Adding toleration for CriticalAddonsOnly taint
  set {
    name  = "tolerations[0].key"
    value = "CriticalAddonsOnly"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }
}
