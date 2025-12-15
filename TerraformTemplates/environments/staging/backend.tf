# ============================================================
# ☁️ Terraform Backend Configuration (Optional)
# ============================================================
# This file defines how Terraform stores its state remotely.
# You can choose between:
#
#  1️⃣ S3 + DynamoDB backend (recommended for AWS self-hosted)
#      → Use the addon: addons/remote-backend.tf
#
#  2️⃣ Terraform Cloud backend (fully managed)
#      → Use the addon: addons/tfcloud-integration.tf
#
# If you're using one of the addons above,
# KEEP THIS SECTION COMMENTED OUT.
#
# ============================================================
# Example manual backend configuration:
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
# ⚠️ Notes:
# • Only ONE backend block can exist per Terraform workspace.
# • addons/remote-backend.tf and tfcloud-integration.tf will
#   automatically provide a working backend when selected
#   using terraform-template.sh → Addons menu.
# • Keep this file for reference or manual customization.
# ============================================================
