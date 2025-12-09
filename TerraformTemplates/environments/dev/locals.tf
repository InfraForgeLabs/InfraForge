locals {
  name_prefix = "${var.project}-dev"
  tags = {
    Project     = var.project
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
