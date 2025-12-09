# ============================================================
# 📦 Outputs — Network Module
# ============================================================

output "vpc_id" {
  description = "VPC ID created by this module"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public Subnet ID (for compute module use)"
  value       = aws_subnet.public.id
}
