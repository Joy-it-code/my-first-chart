variable "region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where resources are deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for EKS and EC2"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI for Jenkins EC2"
  type        = string
}

variable "key_name" {
  description = "SSH Key for EC2"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name of ECR repository"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "jenkins_iam_role_name" {
  description = "IAM role name for Jenkins EC2"
  type        = string
  default     = "jenkins-ec2-role"
}

variable "jenkins_policy_name" {
  description = "IAM policy name for Jenkins EC2"
  type        = string
  default     = "jenkins-ec2-policy"
}

variable "jenkins_instance_profile_name" {
  description = "Instance profile name for Jenkins EC2"
  type        = string
  default     = "jenkins-instance-profile"
}
