output "observability_public_ip" {
  value       = var.enable_observability ? module.observability_ec2[0].public_ip : null
  description = "Public IP of observability EC2"
}

output "grafana_url" {
  value       = var.enable_observability ? module.observability_ec2[0].grafana_url : null
  description = "Grafana URL"
}