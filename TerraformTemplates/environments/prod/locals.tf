locals {
  name_prefix = "${var.project}-prod"
  tags = {
    Project     = var.project
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
