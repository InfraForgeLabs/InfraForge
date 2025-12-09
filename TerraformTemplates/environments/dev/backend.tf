# ============================================================
# 🏗️ Backend Configuration (Optional)
# ============================================================
# You can configure the remote backend manually here,
# or use the automated addon:
#
#   addons/remote-backend.tf  → for S3 + DynamoDB
#   addons/tfcloud-integration.tf → for Terraform Cloud
#
# Example:
#
# terraform {
#   backend "s3" {
#     bucket         = "{{PROJECT}}-tfstate"
#     key            = "env/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "{{PROJECT}}-lock"
#   }
# }
#
# ============================================================
