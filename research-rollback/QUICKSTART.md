# Quick Reference Guide

## Created Files Summary

All files from AGENTS.md have been successfully created. Here's what you have:

### Application (app/)
- ✅ `app/main.py` - FastAPI HTTP server with health endpoints
- ✅ `app/requirements.txt` - Python dependencies (fastapi, uvicorn)
- ✅ `app/README.md` - Application documentation

### Container & Build
- ✅ `Dockerfile` - Slim Python image definition

### Automation Scripts (scripts/)
- ✅ `scripts/build.sh` - Build Docker image with YYYYMMDD.N tag
- ✅ `scripts/push.sh` - Push image to registry
- ✅ `scripts/set-image.sh` - Update manifest image tags
- ✅ `scripts/run-smoke.sh` - Run post-deploy smoke tests
- ✅ `scripts/gen-failure.sh` - Enable feature flag to trigger failures
- ✅ `scripts/restore-config.sh` - Restore stable configuration

### Kubernetes Manifests - Base (kubectl mode)
- ✅ `k8s-manifests/base/namespace.yaml` - Namespace creation
- ✅ `k8s-manifests/base/deployment.yaml` - Deployment with probes
- ✅ `k8s-manifests/base/service.yaml` - Service exposure
- ✅ `k8s-manifests/base/configmap-v1.yaml` - Configuration (feature flags)
- ✅ `k8s-manifests/base/secret-v1.yaml` - Secrets (DB_DSN)
- ✅ `k8s-manifests/base/smoke-test-job.yaml` - Health check job

### Database Migrations
- ✅ `k8s-manifests/db/migrator-job-up.yaml` - Database upgrade job
- ✅ `k8s-manifests/db/migrator-job-down.yaml` - Database rollback job
- ✅ `k8s-manifests/db/pvc-or-notes.md` - Migration strategy documentation

### Argo Rollouts (Advanced mode)
- ✅ `k8s-manifests/rollouts/rollout.yaml` - Canary deployment config
- ✅ `k8s-manifests/rollouts/analysis-template.yaml` - Prometheus metrics analysis
- ✅ `k8s-manifests/rollouts/service-and-ingress.yaml` - Services and Ingress

### Argo CD Configuration
- ✅ `argo/app.yaml` - Argo CD Application resource
- ✅ `argo/hooks/presync-backup.yaml` - Pre-sync hook (backup simulation)
- ✅ `argo/hooks/postsync-smoke.yaml` - Post-sync hook (smoke tests)
- ✅ `argo/README.md` - Argo CD usage documentation

### Build & Documentation
- ✅ `Makefile` - Complete build and deployment automation
- ✅ `README.md` - Comprehensive project documentation

## Next Steps (When Ready to Deploy)

### Test Environment Setup
```bash
# Make scripts executable
chmod +x scripts/*.sh

# View available make targets
make help
```

### Quick Test Deployment
```bash
# Build image locally (for kind/k3d)
make build

# Deploy to cluster
make set-image deploy wait

# Run smoke tests
make smoke

# Check logs
make logs
```

### Feature Testing
```bash
# Enable buggy feature (causes failures)
make fail-on

# Monitor failures
make logs

# Rollback
make undo

# Restore
make fail-off
```

## Key Configuration Variables

Edit in `Makefile`:
```makefile
REG ?= registry.local    # Change to your registry
IMG ?= $(REG)/myapp      # Image name
TAG ?= $(shell date +%Y%m%d).1  # Auto-incremented tag
NS  ?= test-rollback     # Kubernetes namespace
```

## File Structure

```
research-rollback/
├── app/                          # Application source
│   ├── main.py                   # HTTP server endpoints
│   ├── requirements.txt           # Dependencies
│   └── README.md
├── Dockerfile                     # Container image
├── k8s-manifests/
│   ├── base/                      # kubectl deployment
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap-v1.yaml
│   │   ├── secret-v1.yaml
│   │   └── smoke-test-job.yaml
│   ├── db/                        # Database migrations
│   │   ├── migrator-job-up.yaml
│   │   ├── migrator-job-down.yaml
│   │   └── pvc-or-notes.md
│   └── rollouts/                  # Argo Rollouts
│       ├── rollout.yaml
│       ├── analysis-template.yaml
│       └── service-and-ingress.yaml
├── argo/                          # Argo CD config
│   ├── app.yaml
│   ├── hooks/
│   │   ├── presync-backup.yaml
│   │   └── postsync-smoke.yaml
│   └── README.md
├── scripts/                       # Automation
│   ├── build.sh
│   ├── push.sh
│   ├── set-image.sh
│   ├── run-smoke.sh
│   ├── gen-failure.sh
│   └── restore-config.sh
├── Makefile
├── README.md
└── AGENTS.md (requirements)
```

## Application Features

The app provides:

| Endpoint | Purpose | Behavior |
|----------|---------|----------|
| `GET /` | Connectivity | Returns 200 |
| `GET /live` | Liveness probe | Always 200 (container running) |
| `GET /ready` | Readiness probe | 503 until BOOT_DELAY (default 5s) |
| `GET /healthz` | Health check | 200 if DB_DSN set, else 500 |
| `GET /feature/new` | Feature flag test | Returns 500 50% of time if FEATURE_NEW=true |

## Common Use Cases

### Build and Deploy
```bash
make build push set-image deploy wait smoke
```

### Test Failure & Recovery
```bash
make deploy wait    # Deploy stable version
make fail-on wait   # Enable buggy feature
make logs          # See failures
make undo fail-off # Rollback
make smoke         # Verify recovery
```

### Argo CD Deployment
```bash
make argo-app          # Create Argo app
make argo-sync         # Sync from Git
make argo-rollback     # Manual rollback
```

## All Files Created ✓

**Total: 28 files created**

- 1 Python application (main.py)
- 1 Dockerfile
- 6 shell scripts
- 10 Kubernetes manifests
- 2 database migration jobs
- 1 database notes/strategy doc
- 3 Argo Rollouts manifests
- 3 Argo CD files
- 1 Makefile
- 2 README files

Everything is ready. When you're ready to deploy, just run:
```bash
cd /home/cbe/research-k8s/research-rollback
make help
```
