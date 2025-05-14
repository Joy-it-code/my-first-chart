provider "aws" {
  region = var.region
}

# 1. Security Group for Jenkins EC2
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH, HTTP, and Jenkins access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "JenkinsSecurityGroup"
  }
}

# 2. Jenkins EC2 Instance
resource "aws_instance" "jenkins_server" {
  ami                         = var.ami_id
  instance_type               = "t3.medium"
  iam_instance_profile        = aws_iam_instance_profile.jenkins_instance_profile.name
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = var.subnet_ids[0]
  associate_public_ip_address = true

  tags = {
    Name = "JenkinsServer"
  }

  user_data = file("jenkins/install_jenkins.sh")
}

# 3. ECR Repository
resource "aws_ecr_repository" "web_app_repo" {
  name = var.ecr_repository_name
}

# 4. EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.36.0"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = var.subnet_ids
  vpc_id          = var.vpc_id
  enable_irsa     = true
}
