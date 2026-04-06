#!/bin/bash

# Deploy the ArgoCD bootstrap application (App of Apps pattern)
# This will automatically deploy the AppProject and all Applications

set -e

echo "🚀 Deploying Fibonacci Bootstrap Application..."
echo

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed"
    exit 1
fi

# Check if connected to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Not connected to a Kubernetes cluster"
    exit 1
fi

# Check if ArgoCD namespace exists
if ! kubectl get namespace argocd &> /dev/null; then
    echo "⚠️  Warning: argocd namespace not found"
    echo "Please install ArgoCD first:"
    echo "  kubectl create namespace argocd"
    echo "  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    exit 1
fi

# Deploy the bootstrap application
echo "Applying bootstrap application..."
kubectl apply -f argocd/bootstrap/app-of-apps.yaml

echo
echo "✅ Bootstrap application deployed successfully!"
echo
echo "The bootstrap app will automatically deploy:"
echo "  1. AppProject: fibonacci"
echo "  2. Application: fibonacci-dev"
echo "  3. Application: fibonacci-test"
echo "  4. Application: fibonacci-prod"
echo
echo "Check status with:"
echo "  kubectl get applications -n argocd"
echo "  argocd app get fibonacci-bootstrap"
echo
echo "⚠️  Don't forget to update the Git repository URL in:"
echo "  - argocd/bootstrap/app-of-apps.yaml"
echo "  - argocd/applications/*.yaml"
