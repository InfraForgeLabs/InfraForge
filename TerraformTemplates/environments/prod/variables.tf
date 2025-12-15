variable "project" {
  description = "Project name for Production environment"
  type        = string
}

variable "region" {
  description = "AWS region for Production"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block for Production"
  type        = string
  default     = "10.2.0.0/16"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}
