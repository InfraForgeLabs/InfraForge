# ============================================================
# 🧩 Variables — Monitoring Module
# ============================================================

variable "project" {
  description = "Project name used for tagging and naming resources."
  type        = string
}

variable "region" {
  description = "AWS region where monitoring resources are created."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "retention_in_days" {
  description = "Number of days to retain log events."
  type        = number
  default     = 14
}
