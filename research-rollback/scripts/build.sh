#!/bin/bash
# Build Docker image with tag format YYYYMMDD.N
set -e

IMG="${1:-registry.local/myapp}"
TAG="${2:-$(date +%Y%m%d).1}"

echo "Building image: $IMG:$TAG"
docker build -t "$IMG:$TAG" .

echo "Image built successfully: $IMG:$TAG"
