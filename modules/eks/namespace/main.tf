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
# Creates a Kubernetes namespace in the specified EKS cluster.
# Namespaces are logical partitions in Kubernetes, used to isolate resources within the cluster.
# ------------------------------------------------------------------------

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace # The name of the namespace is specified via a variable.
  }
}
