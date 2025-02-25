output "metrics_server" {
  value     = helm_release.metrics_server
  sensitive = true
}
