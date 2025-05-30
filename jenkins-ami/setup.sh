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
docker --version || { echo "Docker installation failed!"; exit 1; }

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
helm version || { echo "Helm installation failed!"; exit 1; }

# 6. Kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

echo "✅ Jenkins + Docker + Helm + kubectl are installed"