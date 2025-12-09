# ============================================================
# 🌐 Network Module — AWS VPC + Subnets
# Version: 1.0
# ============================================================

# --- AWS Provider ---
provider "aws" {
  region = var.region
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project}-vpc"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --- Public Subnet ---
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 0)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "${var.project}-public-subnet"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project}-igw"
    Project     = var.project
    Environment = var.environment
  }
}

# --- Route Table + Association ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name        = "${var.project}-public-rt"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Data Sources ---
data "aws_availability_zones" "available" {}

# --- Outputs ---
output "vpc_id" {
  description = "VPC ID created by this module"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public Subnet ID for use by compute instances"
  value       = aws_subnet.public.id
}
