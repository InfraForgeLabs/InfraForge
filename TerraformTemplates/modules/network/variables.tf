# ============================================================
# 🧩 Variables — Network Module
# ============================================================

variable "project" {
  description = "Project name used for tagging and naming resources."
  type        = string
}

variable "region" {
  description = "AWS region to deploy network resources."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}
