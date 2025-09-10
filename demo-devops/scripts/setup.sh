#!/bin/bash
set -e

echo "Setting up DevOps Demonstration Project for Development..."

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed. Aborting." >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "AWS CLI is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed. Aborting." >&2; exit 1; }

# Initialize Terraform
echo "Initializing Terraform..."
cd terraform/environments/dev
terraform init

# Plan and apply infrastructure
echo "Planning infrastructure..."
terraform plan -var-file=dev.tfvars -out=tfplan

echo "Applying infrastructure..."
terraform apply tfplan

# Configure kubectl
echo "Configuring kubectl..."
AWS_REGION=$(terraform output -raw region)
EKS_CLUSTER_NAME="demo-devops-dev"

aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME

# Verify cluster access
echo "Verifying cluster access..."
kubectl cluster-info

# Setup monitoring
echo "Setting up monitoring stack..."
cd ../../..
kubectl apply -f kubernetes/monitoring/namespace.yaml
kubectl apply -f kubernetes/monitoring/prometheus.yaml
kubectl apply -f kubernetes/monitoring/grafana.yaml

# Wait for monitoring to be ready
echo "Waiting for monitoring components to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-server -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring

# Install AWS Secrets Manager CSI driver
echo "Installing AWS Secrets Manager CSI driver..."
kubectl apply -k github.com/aws/secrets-store-csi-driver-provider-aws/deployments/eks/offline/

# Deploy application
echo "Deploying application..."
kubectl apply -k kubernetes/base/

# Wait for application to be ready
echo "Waiting for application to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/nginx-app -n app-dev

echo "Setup completed successfully!"
echo "Application is running in development environment."
echo "Monitoring stack is available in the 'monitoring' namespace."
echo "Grafana: kubectl port-forward svc/grafana -n monitoring 3000:3000"
echo "Prometheus: kubectl port-forward svc/prometheus-server -n monitoring 9090:9090"