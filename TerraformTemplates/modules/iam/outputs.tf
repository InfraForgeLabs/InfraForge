# ============================================================
# 📦 Outputs — IAM Module
# ============================================================

output "role_name" {
  description = "IAM Role name created by this module"
  value       = aws_iam_role.app.name
}
