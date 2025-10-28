#!/bin/bash
# Replace image tag in manifest files
set -e

TAG="${1}"
if [ -z "$TAG" ]; then
  echo "Usage: $0 <TAG>"
  echo "Example: $0 20251028.1"
  exit 1
fi

echo "Setting image tag to: $TAG"

# Update base manifests
sed -i "s|image: registry.local/myapp:.*|image: registry.local/myapp:$TAG|g" k8s-manifests/base/deployment.yaml

# Update rollouts manifest
sed -i "s|image: registry.local/myapp:.*|image: registry.local/myapp:$TAG|g" k8s-manifests/rollouts/rollout.yaml

echo "Image tag updated to: $TAG"
