output "eks_name" {
  value = module.eks.cluster_name
}

output "eks_node_group_general" {
  value = module.eks.eks_managed_node_groups["general"]
}
