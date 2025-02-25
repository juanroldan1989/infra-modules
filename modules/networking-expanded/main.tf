# ------------------------------------------------------------------------
# Creates a Virtual Private Cloud (VPC) with a CIDR block of 10.0.0.0/16.
# Enables DNS support and hostnames for resources in the VPC.
# ------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.env}-${var.aws_region}-vpc-main"
    Service = "VPC"
    Purpose = "Main VPC"
  }
}

# ------------------------------------------------------------------------
# Creates a private subnet in availability zone `zone1` within the VPC.
# ------------------------------------------------------------------------

resource "aws_subnet" "private_zone1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = var.zone1

  tags = {
    "Name"                                             = "${var.env}-${var.aws_region}-private-subnet-${var.zone1}"
    "kubernetes.io/role/internal-elb"                  = "1"     # so EKS Cluster and AWS Load Balancer Controller know these subnets can be used for load balancers (internal-elb for private, elb for public).
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned" # Associates subnet with EKS cluster.
  }
}

# ------------------------------------------------------------------------
# Creates a private subnet in availability zone `zone2` within the VPC.
# ------------------------------------------------------------------------

resource "aws_subnet" "private_zone2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = var.zone2

  tags = {
    "Name"                                             = "${var.env}-${var.aws_region}-private-subnet-${var.zone2}"
    "kubernetes.io/role/internal-elb"                  = "1"     # so EKS Cluster and AWS Load Balancer Controller know these subnets can be used for load balancers (internal-elb for private, elb for public).
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned" # Associates subnet with EKS cluster.
  }
}

# ------------------------------------------------------------------------
# Creates a public subnet in availability zone `zone1` with public IP mapping enabled for instances launched in it.
# ------------------------------------------------------------------------

resource "aws_subnet" "public_zone1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = var.zone1
  map_public_ip_on_launch = true

  tags = {
    "Name"                                             = "${var.env}-${var.aws_region}-public-subnet-${var.zone1}"
    "kubernetes.io/role/elb"                           = "1"     # so EKS Cluster and AWS Load Balancer Controller know these subnets can be used for load balancers (internal-elb for private, elb for public).
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned" # Associates subnet with EKS cluster.
  }
}

# ------------------------------------------------------------------------
# Creates a public subnet in availability zone `zone2` with public IP mapping enabled for instances launched in it.
# ------------------------------------------------------------------------

resource "aws_subnet" "public_zone2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = var.zone2
  map_public_ip_on_launch = true

  tags = {
    "Name"                                             = "${var.env}-${var.aws_region}-public-subnet-${var.zone2}"
    "kubernetes.io/role/elb"                           = "1"     # so EKS Cluster and AWS Load Balancer Controller know these subnets can be used for load balancers (internal-elb for private, elb for public).
    "kubernetes.io/cluster/${var.env}-${var.eks_name}" = "owned" # Associates subnet with EKS cluster.
  }
}

# ------------------------------------------------------------------------
# Creates a private route table with a route to the NAT Gateway for outbound internet access.
# ------------------------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.env}-${var.aws_region}-route-table-private"
  }
}

# ------------------------------------------------------------------------
# Creates a public route table with a route to the Internet Gateway for outbound internet access.
# ------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env}-${var.aws_region}-route-table-public"
  }
}

# ------------------------------------------------------------------------
# Associates the private route table with the private subnet in zone1.
# ------------------------------------------------------------------------

resource "aws_route_table_association" "private_zone1" {
  subnet_id      = aws_subnet.private_zone1.id
  route_table_id = aws_route_table.private.id
}

# ------------------------------------------------------------------------
# Associates the private route table with the private subnet in zone2.
# ------------------------------------------------------------------------

resource "aws_route_table_association" "private_zone2" {
  subnet_id      = aws_subnet.private_zone2.id
  route_table_id = aws_route_table.private.id
}

# ------------------------------------------------------------------------
# Associates the public route table with the public subnet in zone1.
# ------------------------------------------------------------------------

resource "aws_route_table_association" "public_zone1" {
  subnet_id      = aws_subnet.public_zone1.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------
# Associates the public route table with the public subnet in zone2.
# ------------------------------------------------------------------------

resource "aws_route_table_association" "public_zone2" {
  subnet_id      = aws_subnet.public_zone2.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------
# Allocates an Elastic IP (EIP) for the NAT Gateway.
# ------------------------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.env}-${var.aws_region}-eip-nat"
  }
}

# ------------------------------------------------------------------------
# Creates a NAT Gateway in the public subnet of zone1 for private subnets's outbound internet access.
# ------------------------------------------------------------------------

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_zone1.id

  tags = {
    Name = "${var.env}-${var.aws_region}-nat_gateway-nat"
  }

  depends_on = [aws_internet_gateway.igw] # Ensures Internet Gateway is created first.
}

# ------------------------------------------------------------------------
# Creates an Internet Gateway (IGW) to provide internet access for public subnets.
# ------------------------------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-${var.aws_region}-internet_gateway-igw"
  }
}
