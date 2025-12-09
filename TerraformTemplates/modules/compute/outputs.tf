# ============================================================
# 📦 Outputs — Compute Module
# ============================================================

output "instance_id" {
  description = "EC2 Instance ID created by this compute module"
  value       = aws_instance.app.id
}
