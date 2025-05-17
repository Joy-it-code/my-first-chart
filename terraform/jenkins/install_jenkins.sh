#!/bin/bash
export HOME=/home/ubuntu
aws eks update-kubeconfig --region us-east-1 --name capstone-eks
cp -r ~/.kube /var/lib/jenkins/
chown -R jenkins:jenkins /var/lib/jenkins/.kube
echo "KUBECONFIG=/var/lib/jenkins/.kube/config" >> /etc/default/jenkins
systemctl restart jenkins
