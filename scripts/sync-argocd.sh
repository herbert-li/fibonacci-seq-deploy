#!/bin/bash

# Sync ArgoCD applications
# Usage: ./sync-argocd.sh [dev|test|prod|all]

ENV=${1:-all}

# Check if argocd CLI is installed
if ! command -v argocd &> /dev/null; then
    echo "Error: argocd CLI is not installed"
    echo "Install with: brew install argocd"
    exit 1
fi

sync_app() {
    local app=$1
    echo "Syncing fibonacci-$app..."

    if argocd app sync "fibonacci-$app" --prune --timeout 300; then
        echo "✅ fibonacci-$app synced successfully"
    else
        echo "❌ Failed to sync fibonacci-$app"
        return 1
    fi
    echo
}

if [[ "$ENV" == "all" ]]; then
    sync_app "dev"
    sync_app "test"
    sync_app "prod"
else
    sync_app "$ENV"
fi

echo "=== Sync complete ==="
