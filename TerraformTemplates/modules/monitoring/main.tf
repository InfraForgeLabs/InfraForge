# ============================================================
# 📊 Monitoring Module — AWS CloudWatch Logs & Dashboard
# Version: 1.0
# ============================================================

# --- AWS Provider ---
provider "aws" {
  region = var.region
}

# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.project}/app"
  retention_in_days = var.retention_in_days

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --- Optional CloudWatch Dashboard Example ---
# Uncomment to enable a project dashboard
# resource "aws_cloudwatch_dashboard" "main" {
#   dashboard_name = "${var.project}-${var.environment}-dashboard"
#   dashboard_body = jsonencode({
#     widgets = [
#       {
#         type = "metric",
#         properties = {
#           metrics = [
#             [ "AWS/EC2", "CPUUtilization", "InstanceId", "i-xxxxxxxx" ]
#           ]
#           title = "EC2 CPU Utilization"
#         }
#       }
#     ]
#   })
# }

# --- Outputs ---
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}
