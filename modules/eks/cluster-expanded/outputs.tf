output "eks_name" {
  value = aws_eks_cluster.eks.name
}

output "eks_node_group_general" {
  value = aws_eks_node_group.general
}
