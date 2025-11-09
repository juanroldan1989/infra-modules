output "vpc_id" {
  value = module.vpc.vpc_id
}

# Private subnets for ECS tasks
output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

# Public subnets for ALB (internet-facing)
output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

# Intra subnets for EKS control plane
output "intra_subnet_ids" {
  value = module.vpc.intra_subnets
}
