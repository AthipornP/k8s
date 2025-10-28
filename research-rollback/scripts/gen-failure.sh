#!/bin/bash
# Enable new feature flag to simulate failure scenario
set -e

NS="${1:-test-rollback}"

echo "Enabling FEATURE_NEW flag in namespace: $NS"

# Patch ConfigMap to enable the buggy feature
kubectl patch configmap myapp-config-v1 -n "$NS" --type merge -p '{"data":{"FEATURE_NEW":"true"}}'

echo "Feature flag enabled. Restarting deployment to pick up changes..."

# Restart deployment to pick up new config
kubectl rollout restart deployment/myapp -n "$NS"

echo "Waiting for rollout to complete..."
kubectl rollout status deployment/myapp -n "$NS" --timeout=5m

echo "✓ Feature enabled and deployment restarted"
