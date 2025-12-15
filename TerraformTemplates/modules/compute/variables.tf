# ============================================================
# 🧩 Variables — Compute Module
# ============================================================

variable "project" {
  description = "Project name used for tagging and naming resources."
  type        = string
}

variable "region" {
  description = "AWS region to deploy the instance."
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Amazon Machine Image (AMI) ID for the EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type to launch."
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance should be launched."
  type        = string
}
