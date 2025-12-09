# ============================================================
# 🌍 Root Environment Wiring — Dev
# Version: 1.0
# Description:
#   Connects this environment to reusable Terraform modules.
#   Each environment (dev/staging/prod) can override variables
#   such as region, instance size, or CIDR blocks.
# ============================================================

# --- Network Module ---
module "network" {
  source   = "../../modules/network"
  project  = var.project
  region   = var.region
  vpc_cidr = var.vpc_cidr
}

# --- Compute Module (Optional) ---
# To enable, provide a valid subnet_id from the network module
# or an existing subnet.
#
# module "compute" {
#   source        = "../../modules/compute"
#   project       = var.project
#   region        = var.region
#   ami_id        = var.ami_id
#   instance_type = "t3.micro"
#   subnet_id     = module.network.public_subnet_id
# }

# --- IAM Module (Optional) ---
# module "iam" {
#   source   = "../../modules/iam"
#   project  = var.project
#   region   = var.region
#   role_set = "basic"
# }

# --- Monitoring Module (Optional) ---
# module "monitoring" {
#   source  = "../../modules/monitoring"
#   project = var.project
#   region  = var.region
# }

# --- Outputs ---
output "vpc_id" {
  description = "VPC ID provisioned by the network module"
  value       = module.network.vpc_id
}

# output "instance_id" {
#   description = "Instance ID from the compute module"
#   va

