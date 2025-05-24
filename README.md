# Configuration Management With Helm

> Automating the CI/CD pipeline of a sample web application using Jenkins, Helm, EKS, ECR, and Terraform on AWS.

---


## Project Overview

This project demonstrates how to:
- Provision infrastructure using Terraform
- Install Jenkins on an EC2 instance
- Use **Amazon ECR** for storing Docker images
- Deploy applications to Amazon EKS using Helm
- Automate the entire process using a CI/CD pipeline


---


## Architecture

```
+----------------+      +------------------+      +--------------------+
|   Developer    | ---> |   GitHub Repo    | ---> |   Jenkins EC2 VM   |
+----------------+      +------------------+      +---------+----------+
                                                     |
                                                     v
                                              Docker Build + Push
                                                to Amazon ECR
                                                     |
                                                     v
                                             Helm Deploy to EKS
                                                     |
                                                     v
                                               App Live on EKS

```

---


## Features
+ Jenkins auto-installs with Helm, Docker, kubectl

+ EC2 and EKS infrastructure provisioned with Terraform

+ CI/CD pipeline triggered on GitHub push

+ Docker images pushed to Amazon ECR

+ Helm chart templates deployed to EKS

+ Credentials and security scoped for DevOps best practices


---



## Project Structure
```
project-root/
MY-FIRST-CHART/
│
├── jenkins-ami/
│   ├── setup.sh
│   └── packer.pkr.hcl
├── terraform/                # Infrastructure code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│
├── helm-chart/
│   └── my-first-chart/
│       ├── Chart.yaml
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   └── ingress.yaml
│       └── values.yaml
│
├── Jenkinsfile               # CI/CD Pipeline
├── README.md                 # Project documentation
└── .gitignore
```

---


## Tools & Technologies

- **Jenkins** — CI/CD automation
- **Helm** — Kubernetes package manager
- **Terraform** — Infrastructure as code (EC2, ECR, EKS provisioning)
- **DockerHub** — Container image build & hosting
- **AWS EC2** — Jenkins host
- **AWS EKS** — Kubernetes cluster for deployments

---



## Pre-requisites
+ AWS IAM User with programmatic access and EKS permissions

+ AWS CLI configured locally

+ Terraform CLI

+ GitHub account + personal repo

+ Jenkins plugins:

+ Git

+ Kubernetes CLI

+ Docker Pipeline

+ Helm

+ AWS Credentials


---

## Step-by-Step Guide

### Create project directory
```
mkdir my-first-chart
cd my-first-chart
```



## Install Packer on Windows
```
choco install packer
packer version
```


## Create Folder for Jenkins Ami
+ Create directory
+ Paste your user-data bash script inside setup.sh.

```
mkdir jenkins-ami && cd jenkins-ami
touch setup.sh
```

**Paste**
```
#!/bin/bash
set -e
exec > >(tee /tmp/setup.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Updating packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# 1. Java
echo "Installing Java..."
sudo add-apt-repository universe -y
sudo add-apt-repository multiverse -y
sudo apt-get update -y
sudo apt install openjdk-17-jre -y
java -version || { echo "Java installation failed!"; exit 1; }

# 2. Jenkins
echo "Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y
sudo chown -R jenkins:jenkins /var/lib/jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins || { echo "Jenkins failed to start!"; exit 1; }

# 3. Docker
echo "Installing Docker..."
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
docker --version || { echo " Docker installation failed!"; exit 1; }

sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

# 4. AWS CLI
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip || { echo "Unzip failed"; exit 1; }
sudo ./aws/install
aws --version
rm -rf aws awscliv2.zip

# 5. Helm
echo "Installing Helm..."
curl -LO https://get.helm.sh/helm-v3.14.2-linux-amd64.tar.gz
tar -zxvf helm-v3.14.2-linux-amd64.tar.gz
sudo install -m 755 linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64 helm-v3.14.2-linux-amd64.tar.gz
helm version || { echo " Helm installation failed!"; exit 1; }

# 6. Kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

echo "Jenkins + Docker + Helm + kubectl are installed"
```

+ Make it executable:
```
chmod +x setup.sh 
```


## Create the Packer Template
+ Create a Packer template file called packer.pkr.hcl:
```
touch packer.pkr.hcl
```

**Paste:**
```
packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  default = "us-east-1"
}

variable "source_ami" {
  default = "ami-0f9de6e2d2f067fca"
}

variable "instance_type" {
  default = "t2.medium"
}

source "amazon-ebs" "jenkins" {
  region                      = var.aws_region
  source_ami                  = var.source_ami
  instance_type               = var.instance_type
  ssh_username                = "ubuntu"
  ami_name                    = "jenkins-ami-{{timestamp}}"
  associate_public_ip_address = true
  communicator                = "ssh"
}

build {
  name = "jenkins-ami"

  sources = [
    "source.amazon-ebs.jenkins"
  ]

  provisioner "file" {
    source      = "setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh"
    ]
  }
}
```

## Build Your AMI
+ Verify AWS CLI configuration

**Run**
```
aws configure
packer init .
packer validate packer.pkr.hcl
packer build packer.pkr.hcl
```
**go to your AWS Console → EC2 → AMIs to see new AMI ID**
![](./img/2.ami.packer.png)


### Create .gitignore

Create a .gitignore file in the root of your project:

 ```
 touch .gitignore
 ```

#### Paste the following into it:
```
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.crash
*.tfvars
*.tfvars.json
override.tf
override.tf.json
terraform.tfstate.backup
.terraform.lock.hcl

# Packer
packer_cache/
*.pkr.hcl.lock
*.pkrvars.hcl
setup-debug.log

# User data scripts
*.log
*.zip
*.bak

# System
.DS_Store
Thumbs.db

# IDEs/editors
.vscode/
.idea/
*.swp
*.swo

# Credentials
*.pem
*.key
.aws/
```


### Git initialization and Push:

+ Create a repo on github

```
git init
git add .gitignore
git add .
git commit -m "Initial project setup with Terraform"
git branch -m master main
git remote add origin https://github.com/yourusername/your-repository.git
git push -u origin main
git status
```


### Step 1: Use Terraform to Set Up AWS Resources
+ Create project folders
+ AWS CLI installed + configured
+ verify terraform installation

```
cd ..
mkdir terraform
cd terraform
aws configure
terraform -v
```
![](./img/1a.terraform.v.png)


### Create terraform/main.tf
touch main.tf
```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name        = "eks-vpc"
    Environment = "dev"
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH, HTTP, and Jenkins access"
  vpc_id      = module.vpc.vpc_id

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

resource "aws_instance" "jenkins_server" {
  ami                         = var.ami_id
  instance_type               = "t3.medium"
  iam_instance_profile        = aws_iam_instance_profile.jenkins_instance_profile.name
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  tags = {
    Name = "JenkinsServer"
  }

user_data = file("jenkins/configure_jenkins.sh")
}

resource "aws_ecr_repository" "web_app_repo" {
  name = var.ecr_repository_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_enabled_log_types    = []
  create_cloudwatch_log_group = false
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

### terraform/variable.tf
touch variable.tf
```
variable "region" {
  description = "AWS region to deploy into"
  type        = string
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
```

### terraform/output.tf
touch output.tf
```
output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_server.public_ip
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.web_app_repo.repository_url
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig_command" {
  value = "aws eks --region us-east-1 update-kubeconfig --name ${module.eks.cluster_name}"
}
```


### terraform/terraform.tfvars
touch terraform.tfvars
```
region                        = "us-east-1"
key_name                      = "your-key-pair"               
ami_id                        = "ami-xxxxxxxxx"  

ecr_repository_name           = "web-app"
cluster_name                  = "capstone-eks"
cluster_version               = "1.29"
jenkins_iam_role_name         = "jenkins-ec2-role"
jenkins_policy_name           = "jenkins-ec2-policy"
jenkins_instance_profile_name = "jenkins-instance-profile"

```

----


### Create iam.tf: IAM Role, Policy, and Instance Profile

```
touch iam.tf
```

**Paste**
```
# IAM role and policy for Jenkins EC2
resource "aws_iam_role" "jenkins_role" {
  name = var.jenkins_iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "jenkins_policy" {
  name = var.jenkins_policy_name
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = var.jenkins_instance_profile_name
  role = aws_iam_role.jenkins_role.name
}
```


## Create Jenkinsfile

**Paste**
```
pipeline {
    agent any

    environment {
        AWS_REGION  = 'us-east-1'
        ECR_REPO    = '<account-id>.dkr.ecr.us-east-1.amazonaws.com/web-app'
        ECR_IMAGE   = "${ECR_REPO}:latest"
        CLUSTER_NAME = 'capstone-eks'
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Build and Push to ECR') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-cred', 
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        echo "Logging into AWS..."
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set default.region $AWS_REGION

                        echo "Logging into Amazon ECR..."
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

                        echo "Building Docker image..."
                        docker build -t $ECR_IMAGE .

                        echo "Pushing Docker image to ECR..."
                        docker push $ECR_IMAGE

                        echo "Cleaning up local images..."
                        docker rmi $ECR_IMAGE || true
                    '''
                }
            }
        }

        stage('Deploy with Helm to EKS') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-cred',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        echo "Configuring AWS CLI for Helm..."
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set default.region $AWS_REGION

                        echo "Updating kubeconfig for EKS..."
                        aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME

                        echo "Deploying with Helm..."
                        helm upgrade --install web-app ./helm/web-app \
                            --namespace default \
                            --set image.repository=$ECR_REPO \
                            --set image.tag=latest
                    '''
                }
            }
        }
    }
}
```



## Create Dockerfile
```
nano Dockerfile 
```

**Paste**
```
# Use Nginx as the base image
FROM nginx:stable

# Copy your web app files into the Nginx HTML directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
```

## Create .dockerignore File

**Paste**
```
*.tar
*.zip
*.log
node_modules
.vscode
.git
*.lz4
```


### Create Jenkins file and directory 
+ Run
```
mkdir -p jenkins
touch jenkins/configure_jenkins.sh
```

### Paste
```
#!/bin/bash

REGION="us-east-1"
CLUSTER_NAME="capstone-eks"
JENKINS_HOME="/var/lib/jenkins"
JENKINS_USER="jenkins"
KUBE_DIR="${JENKINS_HOME}/.kube"
KUBECONFIG_FILE="${KUBE_DIR}/config"

# Update kubeconfig as root
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

# Copy kubeconfig to Jenkins user directory
mkdir -p "$KUBE_DIR"
cp -i /root/.kube/config "$KUBECONFIG_FILE"
chown -R "$JENKINS_USER:$JENKINS_USER" "$KUBE_DIR"

# Export KUBECONFIG for Jenkins service
if ! grep -q "KUBECONFIG=${KUBECONFIG_FILE}" /etc/default/jenkins; then
  echo "KUBECONFIG=${KUBECONFIG_FILE}" >> /etc/default/jenkins
fi

# Restart Jenkins to pick up environment change
systemctl restart jenkins
```



### Make the Shell Script Executable
In your terminal, navigate to the root of your Terraform project, then run:
```
chmod +x jenkins/configure_jenkins.sh

```



### Initialize and Apply
```
terraform init
terraform validate
terraform plan 
terraform apply 
```

### On Terminal:
**Run**
```
aws eks update-kubeconfig --region us-east-1 --name capstone-eks
helm list
kubectl get nodes
kubectl get svc
```


## Step 2: Open Jenkins Dashboard

+ Verify Installation on Jenkins EC2:
```
aws version
helm version
kubectl version --client
docker version
jenkins version
sudo systemctl status jenkins
```


+ Open your web browser and go to:
```
http://<JENKINS_PUBLIC_IP>:8080
```

+ You’ll see a page asking for a secret password.

+ Get it from your terminal:

```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
+ Paste it into the Jenkins UI (browser)

+ Choose “Install suggested plugins”

+ Create admin user (or skip)

![](./img/3a.admin.password.png)
![](./img/2b.admin.pswd.png)
![](./img/3b.install.sugestion.png)
![](./img/3c.users.png)
![](./img/3d.jenkins.startup.png)


## Install Plugins
🔹 Install Plugins in Jenkins

+ Go to Manage Jenkins → Plugins → Available Plugins 

+ Search and install these plugins:

+ Git Plugin (for Git integration)

+ Pipeline Plugin (for CI/CD automation)

+ Docker Commons

+ Kubernetes CLI Plugin (for Helm & Kubernetes)

+ Helm Plugin (for Helm chart deployments)

+ AWS Credentials

+ AWS Steps Plugin"

+ Credentials Binding Plugin (for secure credentials management)
![](./img/3e.installation.png)
![](./img/3f.installatn2.png)
![](./img/3g,git.installn.png)
![](./img/3h.pipeline.installn.png)




### Restart Jenkins after installing plugins:

```
sudo systemctl restart jenkins
sudo systemctl status jenkins
```


## Add Basic Security 

+ Go to Manage Jenkins > Configure Global Security

+ Create a new admin user.

+ Disable "Allow anonymous read access.                                                                 
+ Save your changes.

![](./img/4a.restrict.access.png)



### Fine-tuning Jenkins permissions for better security

+ Enable matrix-based security
+ Administrator (account) → Full access
+ Logged-in Users → Read & View permissions
+ Anonymous Users → No access (Best for security!), Click Save.
 ![](./img/4b.security.pratice.png)

 
### Create Jenkins Credentials

### Create and Run Jenkins Pipeline 

🔹Create a Pipeline Job

+ In Jenkins Dashboard, click “New Item”

+ Enter a name like helm-capstone

+ Choose Pipeline

+ Click OK



### 🔹Configure the Pipeline


**Pipeline Section:**
**Choose:**

**Definition:** Pipeline script from SCM

**SCM**: Git

**Repository URL:** https://github.com/your-username/your-repo.git

**Credentials:** Select github-cred if private

**Script Path:** Jenkinsfile

Click Save.




### Enable Webhooks in Your GitHub Repository
+ Go to your GitHub repository → Click Settings → Webhooks.

+ Click Add webhook.

+ In the Payload URL, enter:
```
http://your-jenkins-server/github-webhook/
```
+ Replace your-jenkins-server with your actual Jenkins URL.

+ Choose application/json as the content type.

+ Under Events, select:

+ Push events 

+ You can also select pull requests or custom triggers.

+ Click Save.



## On Terminal

**Edit ConfigMap Run:**
```
export KUBE_EDITOR=nano
kubectl edit configmap aws-auth -n kube-system
```

**Add Jenkins Role**
```
    - rolearn: arn:aws:iam::<account-id>:role/jenkins-role-name
      username: jenkins
      groups:
        - system:masters
```

### To Confirm Role 
run
```
kubectl -n kube-system get configmap aws-auth -o yaml
```





## Step 2: What are Helm Charts?

### What is Helm?
Helm is a package manager for Kubernetes, like apt for Ubuntu or yum for CentOS. Helm lets you define, install, and upgrade Kubernetes applications using charts.




### What is a Helm Chart?
A Helm chart is a collection of YAML templates that describe a set of Kubernetes resources.


### Why Use Helm Charts?

+ It Simplifies deployment with one command: 
```
helm install
helm version
```

+ Reusable and customizable

+ Supports configuration with values files

+ Manages app lifecycle (upgrade, rollback, uninstall)                                                                                  

### Creating a Basic Helm Chart
```
helm create my-first-chart
cd my-first-chart
```


### This creates folders like:

**Chart.yaml:** chart metadata

**values.yaml:** configurable app values (e.g., image name)

**templates/:** deployment and service YAMLs



## Edit the Chart and Update the Following

**Chart.yaml**
```
apiVersion: v2
name: my-first-chart
description: A simple Helm chart for web app
version: 0.1.0
appVersion: "1.0"
```


**values.yaml**

```
replicaCount: 2

image:
  repository: <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-first-chart
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80

resources: {}
```




**templates/deployment.yaml**
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-first-chart.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "my-first-chart.name" . }}
  template:
    metadata:
      labels:
        app: {{ include "my-first-chart.name" . }}
    spec:
      containers:
        - name: my-first-chart
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 80
```



**templates/service.yaml**
```
apiVersion: v1
kind: Service
metadata:
  name: {{ include "my-first-chart.fullname" . }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app: {{ include "my-first-chart.name" . }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
```



### On The Instance Run:
```
nano Dockerfile
```

**Paste**
```
# Use Nginx as the base image
FROM nginx:stable

# Copy your web app files into the Nginx HTML directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
```

### Use Helm Chart in Jenkins Pipeline
On Jenkinsfile :

+ Log into AWS ECR

+ Builds and pushes image

+ Runs Helm upgrade


```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account_id>.dkr.ecr.us-east-1.amazonaws.com
docker build -t web-app .
docker tag web-app:latest <account_id>.dkr.ecr.us-east-1.amazonaws.com/web-app:latest
docker push <account_id>.dkr.ecr.us-east-1.amazonaws.com/web-app:latest 
```


### Verify after deploying:
```
kubectl get pods
kubectl get svc
```


## Step 3: Deploying the App with Helm

### Package and Deploy
```
helm install my-first-chart ./my-first-chart
```

### To upgrade:
```
helm upgrade my-first-chart ./my-first-chart
```

### To rollback:
```
helm rollback my-first-chart 1
```



### To uninstall:
```
helm uninstall my-first-chart
```




## Step 4: Understanding Templates & Values

**values.yaml**

You can override anything from values.yaml at runtime:

```
helm install web-app ./web-app --set replicaCount=3
```

### Templating
Files in **templates/** use Go templating:

```
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```


## Step 5: Integrating Helm with Jenkins

+ **Goal**
Automatically deploy the app to EKS using Helm from Jenkins when code is pushed.                                                                                     
###   Verify Jenkins    Integration Inside Jenkins:

```
helm version
aws eks list-clusters
```


## Add AWS Credentials in Jenkins
+ Go to: Jenkins > Manage Jenkins > Credentials

+ Add AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY as Username/Password credentials

+ Give ID: aws-cred


### 🔹Run the Pipeline

+ On every Push to Github

+ Watch console output for stages:

+ Checkout

+ Build Docker image

+ Push to ECR

+ Deploy with Helm


### Helm Values File Override in Jenkins

**generate a values.yaml:**
```
cat <<EOF > temp-values.yaml
image:
  repository: $ECR_REPO
  tag: latest
replicaCount: 3
EOF

helm upgrade --install web-app ./helm/web-app -f temp-values.yaml
```