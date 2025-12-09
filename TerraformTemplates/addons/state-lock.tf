# ============================================================
# 🔒 Terraform State Lock Table (DynamoDB)
# Version: 1.0
# Description: Prevents concurrent Terraform executions
#              by using a DynamoDB table for state locking.
# ============================================================

resource "aws_dynamodb_table" "tf_lock" {
  name         = "{{PROJECT}}-lock"
  billing_mode = "PAY_PER_REQUEST"

  # Primary key used by Terraform to acquire/release locks
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "{{PROJECT}}-lock"
    Environment = "infrastructure"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# 🧩 Notes:
# • This table works together with the S3 backend defined in
#   `addons/remote-backend.tf`
# • Terraform will automatically write a lock entry to this
#   table during `plan` and `apply` to prevent race conditions.
#
# • No additional IAM policy required beyond standard S3+DynamoDB
#   access for Terraform service role.
#
# ============================================================

output "dynamodb_lock_table" {
  description = "Name of the DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.tf_lock.name
}
