# ==================================================================
# 🛡️ security.tf — AWS Security Baseline
# Managed by Terraform Template Generator (Production Ready)
# ==================================================================

# -------------------------------
# 🔑 AWS KMS Key
# -------------------------------
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project} encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project}-kms"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# -------------------------------
# 📦 S3 Bucket for Centralized Logs
# -------------------------------
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project}-logs-${var.environment}"
  acl    = "private"

  force_destroy = false

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.main.id
      }
    }
  }

  tags = {
    Name        = "${var.project}-logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# -------------------------------
# 🔐 IAM Password Policy
# -------------------------------
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 5
}

# -------------------------------
# 🕵️ CloudTrail (Global & Multi-Region)
# -------------------------------
resource "aws_cloudtrail" "main" {
  name                          = "${var.project}-trail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.main.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = {
    Name        = "${var.project}-trail"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# -------------------------------
# 🔧 Supporting Variables
# -------------------------------
variable "project" {
  description = "Project name used for tagging and resource naming"
  type        = string
  default     = "terraform-project"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}
