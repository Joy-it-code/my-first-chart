variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.101.0.0/16"  
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t2.medium"
}

variable "key_name" {
  description = "Name of the existing EC2 Key Pair to use for SSH"
  type        = string
  default     = "main-key"
}
