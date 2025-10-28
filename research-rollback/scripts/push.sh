#!/bin/bash
# Push Docker image to registry
set -e

IMG="${1:-registry.local/myapp}"
TAG="${2:-$(date +%Y%m%d).1}"

echo "Pushing image: $IMG:$TAG"
docker push "$IMG:$TAG"

echo "Image pushed successfully: $IMG:$TAG"
