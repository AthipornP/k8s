#!/bin/bash
# Run smoke tests after deployment
set -e

NS="${1:-test-rollback}"

echo "Running smoke tests in namespace: $NS"

# Apply smoke test job
kubectl apply -n "$NS" -f k8s-manifests/base/smoke-test-job.yaml

# Wait for job to complete (timeout 5 minutes)
echo "Waiting for smoke test job to complete..."
if kubectl wait --for=condition=complete job/smoke-test --namespace="$NS" --timeout=300s 2>/dev/null; then
  echo "✓ Smoke tests passed"
  # Show job logs
  POD=$(kubectl get pods -n "$NS" -l job-name=smoke-test -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  if [ -n "$POD" ]; then
    echo "Job logs:"
    kubectl logs -n "$NS" "$POD"
  fi
else
  echo "✗ Smoke tests failed or timed out"
  # Show job logs for debugging
  POD=$(kubectl get pods -n "$NS" -l job-name=smoke-test -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  if [ -n "$POD" ]; then
    echo "Job logs:"
    kubectl logs -n "$NS" "$POD"
  fi
  exit 1
fi
