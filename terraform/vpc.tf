module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "jenkins-eks-vpc"
  cidr = "10.101.0.0/16"  

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.101.1.0/24", "10.101.2.0/24"]
  public_subnets  = ["10.101.3.0/24", "10.101.4.0/24"]

  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = {
    Name        = "jenkins-eks-vpc"
    Environment = "dev"
  }
}

