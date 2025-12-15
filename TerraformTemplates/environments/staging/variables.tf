variable "project" {
  description = "Project name for Staging environment"
  type        = string
}

variable "region" {
  description = "AWS region for Staging"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block for Staging"
  type        = string
  default     = "10.1.0.0/16"
}

variable "ami_id" {
  description = "AMI ID for Staging compute nodes"
  type        = string
  default     = "ami-xxxxxxxx"
}
