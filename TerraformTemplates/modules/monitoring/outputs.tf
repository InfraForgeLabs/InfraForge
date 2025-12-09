# ============================================================
# 📦 Outputs — Monitoring Module
# ============================================================

output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.app.name
}
