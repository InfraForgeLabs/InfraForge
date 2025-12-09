# ============================================================
# 🧩 Variables — IAM Module
# ============================================================

variable "project" {
  description = "Project name used for naming and tagging IAM role."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}
