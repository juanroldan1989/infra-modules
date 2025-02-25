# ------------------------------------------------------------------------
# This resource defines the IAM role for the EKS cluster, allowing the EKS service
# to assume this role during cluster operations.
# EKS requires this role to access AWS resources on your behalf.
# ------------------------------------------------------------------------

resource "aws_iam_role" "eks" {
  name = "${var.env}-${var.eks_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "eks.amazonaws.com"
      }
    }
  ]
}
POLICY
}

# ------------------------------------------------------------------------
# This resource attaches the AmazonEKSClusterPolicy to the IAM role, granting
# necessary permissions for the EKS cluster.
# ------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

# ------------------------------------------------------------------------
# This resource creates an Amazon EKS Cluster with the specified configuration,
# including version, role ARN, and VPC subnets for the cluster's networking.
# ------------------------------------------------------------------------

resource "aws_eks_cluster" "eks" {
  name     = "${var.env}-${var.eks_name}"
  version  = var.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true

    subnet_ids = var.private_subnets
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks]

  tags = {
    Name = "${var.env}-${var.eks_name}"
  }
}

# ------------------------------------------------------------------------
# This resource defines the IAM role for EKS worker nodes, allowing EC2 instances
# (nodes) to assume this role when operating as part of the EKS cluster.
# ------------------------------------------------------------------------

resource "aws_iam_role" "nodes" {
  name = "${var.env}-${var.eks_name}-eks-nodes"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
POLICY
}

# ------------------------------------------------------------------------
# This resource attaches the AmazonEKSWorkerNodePolicy to the IAM role for worker
# nodes, providing permissions needed by the worker nodes in the EKS cluster.
# This policy now includes AssumeRoleForPodIdentity for the Pod Identity Agent
# ------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

# ------------------------------------------------------------------------
# This resource attaches the AmazonEKS_CNI_Policy to the IAM role for worker nodes,
# allowing the container network interface to function properly in the EKS cluster.
# ------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

# ------------------------------------------------------------------------
# This resource attaches the AmazonEC2ContainerRegistryReadOnly policy to the IAM
# role for worker nodes, enabling the nodes to pull container images from ECR.
# ------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

# ------------------------------------------------------------------------
# This resource creates an EKS node group ("managed node group")
# for the cluster with specified configurations,
# such as instance type, capacity type, scaling configuration, and tags.
# ------------------------------------------------------------------------

resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.eks.name
  version         = var.eks_version
  node_group_name = "general"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = var.private_subnets

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]

  tags = {
    Name = "${var.env}-${var.eks_name}-eks-node-group-general"
  }
}
