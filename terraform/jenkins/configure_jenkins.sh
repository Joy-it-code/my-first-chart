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
