terraform {
  required_version = ">= 1.4.0"

  required_providers {
    infracost = {
      source  = "infracost/infracost"
      version = "~> 1.0"
    }
  }
}

# 🔹 Infracost Provider Configuration
provider "infracost" {
  api_key = var.infracost_api_key
}

# 🔹 Example (Reference via CI/CD)
# The Infracost CLI runs outside Terraform but reads plan JSONs.
# You can generate cost breakdowns automatically in your pipelines.

# Example Terraform usage reference:
#
# terraform plan -out=tfplan.binary
# terraform show -json tfplan.binary > plan.json
# infracost breakdown --path plan.json --format table
#
# Or in Jenkins:
#
# stage('Cost Estimation') {
#   steps {
#     sh '''
#     infracost breakdown --path plan.json \
#       --format json --out-file infracost-report.json
#     infracost comment github --path infracost-report.json \
#       --repo $GITHUB_REPOSITORY --pull-request $PR_NUMBER \
#       --behavior update
#     '''
#   }
# }

# 🔹 Output placeholder
output "infracost_status" {
  value = "Infracost integration is configured. Run 'infracost breakdown' in CI."
}

# 🔹 Variables
variable "infracost_api_key" {
  description = "Infracost API key used for authenticating cost estimation requests."
  type        = string
  sensitive   = true
}
