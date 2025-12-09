output "cluster_name" {
  description = "ECS Cluster Name"
  value       = module.ecs.cluster_name
}

output "cluster_id" {
  description = "ECS Cluster ID"
  value       = module.ecs.cluster_id
}
