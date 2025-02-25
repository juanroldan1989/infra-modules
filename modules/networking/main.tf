module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "${var.env}-${var.aws_region}-vpc-main"
  cidr = "10.0.0.0/16"

  # Define AZs dynamically based on input variables
  azs             = [var.zone1, var.zone2]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]
  intra_subnets   = ["10.0.128.0/19", "10.0.160.0/19"]

  # Enable NAT gateway for private subnets
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # Tag public subnets for Kubernetes Load Balancer discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb"                           = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }

  # Tag private subnets for Kubernetes and Karpenter
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                  = "1"
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
    "karpenter.sh/discovery"                           = "${var.env}-${var.eks_name}"
  }

  # Tag intra subnets for EKS Control Plane nodes
  # These subnets are used for EKS control plane nodes and other internal services
  # These subnets do not need internet access (no NAT or Internet Gateway)
  intra_subnet_tags = {
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned"
  }
}
