#!/bin/bash

CLUSTER_NAME="capstone-eks"
REGION="us-east-1"

echo "Setting up kubeconfig for EKS cluster: $CLUSTER_NAME"

aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

if [ $? -eq 0 ]; then
  echo "✅ Kubeconfig set successfully."
else
  echo "❌ Failed to set kubeconfig."
  exit 1
fi
