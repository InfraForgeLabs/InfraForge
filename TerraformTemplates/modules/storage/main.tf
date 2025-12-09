# ============================================================
# 🪣 Storage Module — AWS S3 Bucket
# Version: 1.0
# ============================================================

# --- AWS Provider ---
provider "aws" {
  region = var.region
}

# --- S3 Bucket ---
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.project}-${var.environment}-bucket"

  tags = {
    Name        = "${var.project}-${var.environment}-bucket"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --- Enable Versioning ---
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- Enable Default Encryption ---
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Public Access Block ---
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Outputs ---
output "bucket_name" {
  description = "S3 bucket name created by this module"
  value       = aws_s3_bucket.bucket.bucket
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.bucket.arn
}
