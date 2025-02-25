output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = module.vpc.private_subnets
}

output "intra_subnet_ids" {
  value = module.vpc.intra_subnets
}
