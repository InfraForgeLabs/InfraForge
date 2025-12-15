output "vpc_id" {
  description = "VPC ID provisioned by the network module"
  value       = module.network.vpc_id
}
