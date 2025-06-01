resource "aws_iam_role" "jenkins_eks_ecr_role" {
  name = "jenkins-eks-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.jenkins_eks_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_access" {
  role       = aws_iam_role.jenkins_eks_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_access" {
  role       = aws_iam_role.jenkins_eks_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_instance_profile" "jenkins_eks_ecr_instance_profile" {
  name = "jenkins-eks-ecr-instance-profile"
  role = aws_iam_role.jenkins_eks_ecr_role.name
}
