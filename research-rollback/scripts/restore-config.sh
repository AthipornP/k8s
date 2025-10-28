#!/bin/bash
# Restore config to stable state (disable new feature)
set -e

NS="${1:-test-rollback}"

echo "Disabling FEATURE_NEW flag in namespace: $NS"

# Patch ConfigMap to disable the feature
kubectl patch configmap myapp-config-v1 -n "$NS" --type merge -p '{"data":{"FEATURE_NEW":"false"}}'

echo "Feature flag disabled. Restarting deployment to pick up changes..."

# Restart deployment to pick up new config
kubectl rollout restart deployment/myapp -n "$NS"

echo "Waiting for rollout to complete..."
kubectl rollout status deployment/myapp -n "$NS" --timeout=5m

echo "✓ Config restored to stable state"
