# ============================================================
# ⚙️ Compute Module — AWS EC2 Instance
# Version: 1.0
# ============================================================

# --- Provider ---
provider "aws" {
  region = var.region
}

# --- EC2 Instance ---
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  tags = {
    Name        = "${var.project}-instance"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --- Outputs ---
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app.id
}
