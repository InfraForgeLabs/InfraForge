# ============================================================
# ☁️ Terraform Cloud Integration Addon
# Version: 1.0
# Description: Configures Terraform Cloud or Enterprise as the
#              remote backend for state and operations.
# ============================================================

terraform {
  cloud {
    # 🏢 Organization name in Terraform Cloud
    organization = "{{PROJECT}}-org"

    # 🧰 Workspace to store remote state and execute runs
    workspaces {
      name = "{{PROJECT}}-workspace"
    }
  }
}

# ============================================================
# 🧩 Notes:
# 1️⃣ Terraform Cloud replaces S3 + DynamoDB backends.
#    You do NOT need `remote-backend.tf` or `state-lock.tf`
#    when using this addon.
#
# 2️⃣ Ensure Terraform Cloud API credentials are set:
#     export TF_TOKEN_app_terraform_io="your-api-token"
#
# 3️⃣ Initialize your workspace:
#     terraform login
#     terraform init
#
# 4️⃣ To link CLI runs to Terraform Cloud:
#     terraform plan
#     terraform apply
#    (These commands will now execute remotely on Terraform Cloud.)
#
# ============================================================

output "tf_cloud_info" {
  description = "Terraform Cloud organization and workspace info."
  value = {
    organization = "{{PROJECT}}-org"
    workspace    = "{{PROJECT}}-workspace"
  }
}
