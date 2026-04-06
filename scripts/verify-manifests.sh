#!/bin/bash
set -e

echo "=== Verifying Kubernetes Manifests ==="
echo

# Check if kustomize is installed
if ! command -v kustomize &> /dev/null; then
    echo "Error: kustomize is not installed"
    echo "Install with: brew install kustomize"
    exit 1
fi

# Environments to verify
ENVIRONMENTS=("dev" "test" "prod")

for env in "${ENVIRONMENTS[@]}"; do
    echo "Verifying $env environment..."

    # Build kustomization
    if ! kustomize build "overlays/$env" > /dev/null; then
        echo "❌ Failed to build $env manifests"
        exit 1
    fi

    echo "✅ $env manifests are valid"
    echo
done

echo "=== All manifests verified successfully ==="
