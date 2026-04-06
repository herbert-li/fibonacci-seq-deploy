#!/bin/bash
set -e

# Update image tag for a specific environment
# Usage: ./update-image.sh <env> <image:tag>

ENV=$1
IMAGE=$2

if [[ -z "$ENV" ]] || [[ -z "$IMAGE" ]]; then
    echo "Usage: $0 <env> <image:tag>"
    echo "Example: $0 prod docker.io/myuser/fibonacci-api:v1.2.3"
    exit 1
fi

if [[ ! -d "overlays/$ENV" ]]; then
    echo "Error: Environment '$ENV' does not exist"
    echo "Available environments: dev, test, prod"
    exit 1
fi

echo "Updating $ENV environment to use image: $IMAGE"

cd "overlays/$ENV"
kustomize edit set image "fibonacci-api=$IMAGE"

echo "✅ Updated overlays/$ENV/kustomization.yaml"
echo
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Commit the changes: git commit -am 'Update $ENV to $IMAGE'"
echo "3. Push to trigger ArgoCD sync: git push"
