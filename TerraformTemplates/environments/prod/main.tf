# ============================================================
# 🌍 Root Environment Wiring — Dev
# Version: 1.0
# Description:
#   Example of how this environment connects reusable modules
#   such as network, compute, IAM, etc.
#
#   Each environment (dev/staging/prod) can have its own
#   configuration values and variable overrides.
# ============================================================

# --- Network Module ---
module "network" {
  source   = "../../modules/network"
  project  = var.project
  region   = var.region
  vpc_cidr = var.vpc_cidr
}

# --- Compute Module (Optional) ---
# Uncomment and configure subnet_id after the network module
# creates subnets or if using an existing one.
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
#   value       = module.compute.instance_id
# }

# ============================================================
# 🧩 Notes:
# • Addons (e.g., remote-backend.tf, tfcloud-integration.tf,
#   cost-estimation.tf) can be added dynamically by your
#   terraform-template.sh generator.
# • All .tf files in this directory are auto-merged by Terraform.
# • Variable definitions for this file are in variables.tf.
# ============================================================
