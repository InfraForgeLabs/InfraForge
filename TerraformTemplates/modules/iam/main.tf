# ============================================================
# 🔐 IAM Module — AWS EC2 Role
# Version: 1.0
# ============================================================

# --- AWS IAM Role ---
resource "aws_iam_role" "app" {
  name = "${var.project}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --- Optional IAM Policy Attachment Example ---
# Uncomment or extend as needed
# resource "aws_iam_role_policy_attachment" "ec2_attach" {
#   role       = aws_iam_role.app.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# --- Outputs ---
output "role_name" {
  description = "IAM role name created by this module"
  value       = aws_iam_role.app.name
}
