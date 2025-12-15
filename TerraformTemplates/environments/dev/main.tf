# ============================================================
# 🌍 Root Environment Wiring — Dev
# Description: Example of how to connect reusable modules
# ============================================================

# --- Network Module ---
module "network" {
  source   = "../../modules/network"
  project  = var.project
  region   = var.region
  vpc_cidr = var.vpc_cidr
}

# --- Compute Module (optional) ---
# module "compute" {
#   source        = "../../modules/compute"
#   project       = var.project
#   region        = var.region
#   ami_id        = var.ami_id
#   instance_type = "t3.micro"
#   subnet_id     = module.network.public_subnet_id
# }

# --- Outputs ---
output "vpc_id" {
  description = "VPC ID provisioned by the network module"
  value       = module.network.vpc_id
}
