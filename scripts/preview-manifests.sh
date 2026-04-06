#!/bin/bash

# Preview manifests for a specific environment
# Usage: ./preview-manifests.sh [dev|test|prod]

ENV=${1:-dev}

if [[ ! -d "overlays/$ENV" ]]; then
    echo "Error: Environment '$ENV' does not exist"
    echo "Available environments: dev, test, prod"
    exit 1
fi

echo "=== Preview manifests for $ENV environment ==="
echo

kustomize build "overlays/$ENV"
