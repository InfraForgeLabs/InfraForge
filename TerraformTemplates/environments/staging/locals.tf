locals {
  name_prefix = "${var.project}-staging"
  tags = {
    Project     = var.project
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}
