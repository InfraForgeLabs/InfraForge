variable "project" {
  description = "Project name for Dev environment"
  type        = string
}

variable "region" {
  description = "AWS region for Dev"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block for Dev"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (Dev testing)"
  type        = string
  default     = "ami-xxxxxxxx"
}
