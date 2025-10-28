# K8s Deployment & Rollback Demo

A comprehensive example project demonstrating Kubernetes deployment strategies, health checks, and automated rollback mechanisms. Supports both manual `kubectl` deployments and automated Argo CD + Argo Rollouts deployments.

## Project Overview

This project provides:

- **Example Application**: Simple HTTP server with health checks and feature flags
- **Container Setup**: Dockerfile with slim Python base image
- **Kubernetes Manifests**: Base deployment and advanced Argo Rollouts configuration
- **Automation Scripts**: Build, deploy, test, and failure simulation
- **Multiple Deployment Modes**:
  - Manual: Using `kubectl` only
  - Advanced: Using Argo CD + Argo Rollouts with automatic rollback

## Quick Start

### Prerequisites

- Kubernetes cluster (local `kind`/`k3d` or cloud)
- `kubectl` configured
- Docker for building images
- `make` utility
- (Optional) Argo CD and Argo Rollouts installed for advanced mode

### Basic Deployment (kubectl mode)

```bash
# Build and push container image
make build push

# Deploy to cluster
make set-image deploy wait

# Run smoke tests
make smoke
```

### Test Failure Scenario

```bash
# Enable buggy feature (will cause readiness probe failures)
make fail-on

# Observe failures in the deployment
make logs

# Rollback to previous stable version
make undo

# Restore config to stable state
make fail-off
```

## Project Structure

```
.
├── app/                       # Application source code
│   ├── main.py               # FastAPI HTTP server with health checks
│   ├── requirements.txt       # Python dependencies
│   └── README.md             # App documentation
├── Dockerfile                # Container image definition
├── k8s-manifests/
│   ├── base/                 # kubectl deployment manifests
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap-v1.yaml
│   │   ├── secret-v1.yaml
│   │   └── smoke-test-job.yaml
│   ├── db/                   # Database migration jobs
│   │   ├── migrator-job-up.yaml
│   │   ├── migrator-job-down.yaml
│   │   └── pvc-or-notes.md
│   └── rollouts/             # Argo Rollouts manifests
│       ├── rollout.yaml
│       ├── analysis-template.yaml
│       └── service-and-ingress.yaml
├── argo/                     # Argo CD configuration
│   ├── app.yaml             # Argo CD Application
│   ├── hooks/
│   │   ├── presync-backup.yaml
│   │   └── postsync-smoke.yaml
│   └── README.md
├── scripts/                  # Automation scripts
│   ├── build.sh
│   ├── push.sh
│   ├── set-image.sh
│   ├── run-smoke.sh
│   ├── gen-failure.sh
│   └── restore-config.sh
├── Makefile                  # Build and deployment automation
└── README.md                 # This file
```

## Application Endpoints

The application runs on port 8080 and exposes:

- `GET /` - Basic connectivity check
- `GET /live` - Liveness probe (always 200)
- `GET /ready` - Readiness probe (503 until BOOT_DELAY seconds)
- `GET /healthz` - Health check (requires DB_DSN)
- `GET /feature/new` - Feature endpoint with failure simulation

### Environment Variables

- `BOOT_DELAY` - Seconds to wait before readiness (default: 5)
- `DB_DSN` - Database connection string (required for /healthz)
- `FEATURE_NEW` - Enable new feature with random failures (default: false)

## Deployment Modes

### Mode 1: Manual kubectl Deployment

Direct Kubernetes API deployment with rolling updates:

```bash
# Full workflow
make build push set-image deploy wait smoke

# Trigger failure
make fail-on

# Observe
make logs

# Rollback
make undo fail-off
```

**Features:**
- Standard Kubernetes Deployment with RollingUpdate strategy
- readiness/liveness probes
- Manual rollback via `kubectl rollout undo`

### Mode 2: Argo CD + Argo Rollouts

GitOps-based deployment with canary releases:

```bash
# Setup (requires Argo CD installed)
make argo-app

# Sync changes from Git
make argo-sync

# Automatic canary progression with analysis
# - 10% traffic for 2 min
# - Analysis checks error rate < 1%
# - 50% traffic for 5 min
# - Analysis checks error rate < 1%
# - 100% traffic (full rollout)

# Trigger failure
make fail-on

# Argo Rollouts automatically aborts and rolls back

# Manual rollback if needed
make argo-rollback
```

**Features:**
- Canary deployment strategy with automatic progression
- Prometheus-based analysis for health checks
- Automatic rollback on analysis failure
- GitOps workflow with Argo CD
- Pre/post-sync hooks for backup and smoke testing

## Deployment Workflow

### Pre-deployment Checklist

1. Set correct image registry (modify `REG` variable or use `make REG=myregistry.com build`)
2. Ensure namespace `test-rollback` exists or will be created
3. Database connectivity configured (optional, for `/healthz` endpoint)
4. Registry credentials available to cluster (if using private registry)

### Standard Deployment Steps

```bash
# 1. Build container image
make build

# 2. Push to registry (optional for local k3d/kind)
make push

# 3. Update manifests with new tag
make set-image

# 4. Deploy to cluster
make deploy

# 5. Wait for readiness
make wait

# 6. Run smoke tests
make smoke

# 7. Monitor in real-time
make logs
```

## Health Checks

The application uses Kubernetes probes for reliability:

### Readiness Probe
- Endpoint: `/ready`
- Purpose: Determines when pod can receive traffic
- Behavior: Returns 503 until `BOOT_DELAY` seconds (default 5) have elapsed
- Probe config: `periodSeconds: 5`, `failureThreshold: 2`

### Liveness Probe
- Endpoint: `/live`
- Purpose: Detects stuck containers
- Behavior: Always returns 200
- Probe config: `periodSeconds: 10`, `failureThreshold: 3`

## Failure Scenarios & Recovery

### Scenario 1: Buggy Feature Rollout

```bash
# Enable buggy feature
make fail-on

# This sets FEATURE_NEW=true, causing /feature/new to randomly fail 50% of the time

# kubectl mode: Manual rollback
make undo
make fail-off

# Argo Rollouts mode: Automatic rollback via analysis failure
# (Error rate > 5% triggers automatic abort and rollback)
```

### Scenario 2: Readiness Probe Failures

```bash
# Simulate slow startup (won't pass readiness for 5 minutes)
kubectl patch configmap myapp-config-v1 -n test-rollback \
  -p '{"data":{"BOOT_DELAY":"300"}}'

# Restart deployment
kubectl rollout restart deployment/myapp -n test-rollback

# Observe readiness probe failures in logs
make logs

# Restore normal behavior
make restore-config
```

## Configuration Variables

In `Makefile`, customize:

```makefile
REG ?= registry.local      # Container registry
IMG ?= $(REG)/myapp        # Image name
TAG ?= $(shell date +%Y%m%d).1  # Tag format: YYYYMMDD.N
NS  ?= test-rollback       # Kubernetes namespace
```

Usage examples:

```bash
# Use different registry
make build push REG=docker.io

# Use specific tag
make deploy TAG=20251028.2

# Use different namespace
make deploy NS=production
```

## Kubernetes Resource Requests & Limits

Pod resources:

```yaml
requests:
  cpu: "200m"
  memory: "256Mi"
limits:
  cpu: "1"
  memory: "512Mi"
```

Adjust in:
- `k8s-manifests/base/deployment.yaml` (kubectl mode)
- `k8s-manifests/rollouts/rollout.yaml` (Argo Rollouts mode)

## Database Migrations

Optional migration jobs for database schema changes:

```bash
# Run migration upgrade
kubectl apply -n test-rollback -f k8s-manifests/db/migrator-job-up.yaml
kubectl wait --for=condition=complete job/db-migrator-up -n test-rollback

# Rollback migration (if reversible)
kubectl apply -n test-rollback -f k8s-manifests/db/migrator-job-down.yaml
kubectl wait --for=condition=complete job/db-migrator-down -n test-rollback
```

See `k8s-manifests/db/pvc-or-notes.md` for database strategy and backup procedures.

## Monitoring & Debugging

### View pod logs
```bash
make logs
```

### Check pod status
```bash
kubectl get pods -n test-rollback -o wide
```

### View events
```bash
kubectl get events -n test-rollback --sort-by='.lastTimestamp'
```

### Check rollout history
```bash
make history
```

### Inspect ConfigMap
```bash
kubectl get configmap myapp-config-v1 -n test-rollback -o yaml
```

## Smoke Tests

Smoke tests are run automatically as a Job after deployment:

```bash
make smoke
```

The test:
1. Waits for the myapp Service to be available
2. Makes HTTP requests to `/healthz` endpoint
3. Retries up to 3 times with 2-second delays
4. Returns 0 (success) if health check passes, 1 (failure) if not

## Cleanup

Remove all resources:

```bash
make clean
```

This deletes the `test-rollback` namespace and all resources within it.

## Argo CD & Rollouts Setup (Optional)

For advanced deployment mode, install:

### Argo Rollouts
```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

### Argo CD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Prometheus (for canary analysis)
```bash
# Install Prometheus for metrics-based analysis
# (Simplified example - in production, use proper Prometheus setup)
```

After setup:
```bash
make argo-app
make argo-sync
```

## Use Cases

### 1. Blue-Green Deployment
Use `kubectl` mode with manual image tag switching:
```bash
make set-image TAG=20251028.1 deploy wait
# Test thoroughly...
# When ready, update again:
make set-image TAG=20251028.2 deploy wait
```

### 2. Canary Release
Use Argo Rollouts mode:
```bash
make argo-app
# Push new code to Git repository
make argo-sync
# Automatic canary progression with metrics-based validation
```

### 3. Rolling Update
Default behavior of kubectl mode:
- 1 pod unavailable at a time
- Automatic readiness checking
- Self-healing on failure

### 4. Feature Flag Testing
Test new features safely:
```bash
make deploy  # Deploy version with new feature disabled
make fail-on # Enable feature (will see failures)
make logs    # Monitor
make undo    # Rollback if needed
```

## Common Issues

### Image pull errors
- Ensure registry credentials are configured
- Check image tag matches what's pushed
- Verify imagePullPolicy setting

### Readiness probe fails
- Check BOOT_DELAY (default 5 seconds)
- Verify container logs: `make logs`
- Ensure /ready endpoint is accessible

### Smoke test fails
- Check Service DNS resolution: `kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- sh`
- Verify application is running: `make logs`
- Check Service endpoints: `kubectl get endpoints -n test-rollback`

### Rollback doesn't work
- Check rollout history: `make history`
- Verify previous revision exists
- Try manual rollback: `kubectl rollout undo deployment/myapp -n test-rollback`

## Additional Resources

- [Kubernetes Deployment Docs](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Argo Rollouts Docs](https://argoproj.github.io/argo-rollouts/)
- [Argo CD Docs](https://argoproj.github.io/argo-cd/)
- [Kubernetes Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

## License

This project is provided as an educational example.
