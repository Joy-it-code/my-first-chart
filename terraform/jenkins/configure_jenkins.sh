#!/bin/bash
set -euo pipefail

REGION="us-east-1"
CLUSTER_NAME="capstone-eks"
JENKINS_HOME="/var/lib/jenkins"
JENKINS_USER="jenkins"
KUBE_DIR="${JENKINS_HOME}/.kube"
KUBECONFIG_FILE="${KUBE_DIR}/config"

# Ensure running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "[ERROR] Please run as root"
  exit 1
fi

# Ensure required tools are installed
command -v aws >/dev/null 2>&1 || { echo "[ERROR] aws CLI not found"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "[ERROR] kubectl not found"; exit 1; }

setup_jenkins_kubeconfig() {
  echo "[INFO] Setting up kubeconfig for Jenkins..."
  aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

  mkdir -p "$KUBE_DIR"
  cp -f /root/.kube/config "$KUBECONFIG_FILE"
  chown -R "$JENKINS_USER:$JENKINS_USER" "$KUBE_DIR"

  if ! grep -q "KUBECONFIG=${KUBECONFIG_FILE}" /etc/default/jenkins; then
    echo "KUBECONFIG=${KUBECONFIG_FILE}" >> /etc/default/jenkins
  fi

  if systemctl is-active --quiet jenkins; then
    systemctl restart jenkins
    echo "[INFO] Jenkins restarted."
  else
    echo "[WARN] Jenkins service not running or systemd not available."
  fi

  echo "[INFO] Jenkins setup complete."
}

cleanup_k8s_resources() {
  echo "[INFO] Starting safe Kubernetes cleanup..."
  aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

  kubectl delete ingress --all || true
  kubectl delete service --all || true
  kubectl delete deployment --all || true
  kubectl delete statefulset --all || true
  kubectl delete pvc --all || true

  echo "[INFO] Kubernetes cleanup complete."
}

if [[ "${1:-}" == "--cleanup" ]]; then
  cleanup_k8s_resources
else
  setup_jenkins_kubeconfig
fi
