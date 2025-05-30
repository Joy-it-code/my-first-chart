variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "key_name" {
  default = "main-key"
}