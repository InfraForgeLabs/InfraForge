terraform {
  # Ensure consistent Terraform version across environments
  required_version = ">= 1.6.0"

  # Provider version pinning for stability
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }

  # Optional backend (overridden dynamically by template or addon)
  # backend "s3" {}
}

# Default AWS provider configuration
provider "aws" {
  region = var.region
}

# -------------------------------
# 🌍 Variables
# -------------------------------

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}
