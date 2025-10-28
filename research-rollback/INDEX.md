# Project Navigation Guide

## 📚 Documentation (Start Here)

| Document | Purpose | Audience |
|----------|---------|----------|
| **[README.md](README.md)** | Comprehensive project guide (1000+ lines) | Everyone |
| **[QUICKSTART.md](QUICKSTART.md)** | Quick reference and examples | Quick learners |
| **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** | What was created and why | Project overview |
| **[COMPLETION_CHECKLIST.md](COMPLETION_CHECKLIST.md)** | Requirements validation | Verification |
| **[AGENTS.md](AGENTS.md)** | Original specifications | Reference |

## 🎯 First Steps

### 1. Understand the Project
```bash
cat README.md          # Full guide
cat QUICKSTART.md      # Quick overview
```

### 2. View Available Commands
```bash
make help
```

### 3. Deploy to Kubernetes
```bash
# kubectl mode (simple)
make build push set-image deploy wait smoke

# Argo CD mode (advanced)
make argo-app argo-sync
```

## 📂 Directory Structure

### `/app` - Application Source Code
```
app/
├── main.py           # FastAPI HTTP server
├── requirements.txt  # Python dependencies
└── README.md        # App documentation
```
**When to visit:** 
- Understanding the application logic
- Modifying health check behavior
- Adding new endpoints

### `/Dockerfile` - Container Definition
**When to visit:** 
- Building custom images
- Changing base image
- Installing additional dependencies

### `/k8s-manifests/base` - kubectl Deployment
```
k8s-manifests/base/
├── namespace.yaml        # Namespace creation
├── deployment.yaml       # Main deployment
├── service.yaml         # Service exposure
├── configmap-v1.yaml    # Configuration
├── secret-v1.yaml       # Credentials
└── smoke-test-job.yaml  # Health checks
```
**When to visit:** 
- Deploying with `kubectl` directly
- Modifying resource limits
- Updating probe configuration

### `/k8s-manifests/db` - Database Operations
```
k8s-manifests/db/
├── migrator-job-up.yaml
├── migrator-job-down.yaml
└── pvc-or-notes.md      # Database strategy
```
**When to visit:** 
- Planning database migrations
- Understanding backup strategy
- Running upgrade/rollback jobs

### `/k8s-manifests/rollouts` - Advanced Deployments
```
k8s-manifests/rollouts/
├── rollout.yaml              # Canary strategy
├── analysis-template.yaml    # Health metrics
└── service-and-ingress.yaml # Services
```
**When to visit:** 
- Using Argo Rollouts
- Understanding canary deployment
- Configuring automatic rollback

### `/argo` - GitOps Configuration
```
argo/
├── app.yaml           # Argo CD Application
├── hooks/
│   ├── presync-backup.yaml
│   └── postsync-smoke.yaml
└── README.md         # Argo documentation
```
**When to visit:** 
- Setting up Argo CD
- Understanding hooks
- Configuring GitOps workflow

### `/scripts` - Automation Scripts
```
scripts/
├── build.sh            # Build image
├── push.sh            # Push to registry
├── set-image.sh       # Update tags
├── run-smoke.sh       # Test health
├── gen-failure.sh     # Enable failures
└── restore-config.sh  # Restore stable
```
**When to visit:** 
- Understanding automation flow
- Modifying deployment scripts
- Creating custom workflows

### `/Makefile` - Build Orchestration
**When to visit:** 
- Understanding available targets
- Customizing build variables
- Creating new workflows

## 🔄 Common Workflows

### Deploy Application
```bash
# 1. Read the guide
cat README.md | grep "Quick Start" -A 20

# 2. Build
make build

# 3. Deploy
make set-image deploy wait

# 4. Verify
make smoke
make logs
```

### Test Failure & Recovery
```bash
# 1. Trigger failure
make fail-on

# 2. Observe
make logs

# 3. Rollback
make undo fail-off

# 4. Verify recovery
make smoke
```

### Use Argo CD
```bash
# 1. Read Argo guide
cat argo/README.md

# 2. Install Argo (if needed)
# Follow official Argo CD installation

# 3. Create app
make argo-app

# 4. Sync
make argo-sync
```

## 🛠️ Configuration

### Change Registry
```bash
make build REG=docker.io
```

### Change Namespace
```bash
make deploy NS=production
```

### Change Tag Format
Edit `Makefile`:
```makefile
TAG ?= your-custom-tag
```

## 📊 Application Endpoints

All endpoints run on `:8080` inside pod:

| Endpoint | Purpose | Use |
|----------|---------|-----|
| `GET /` | Health | Basic check |
| `GET /live` | Liveness | K8s probe |
| `GET /ready` | Readiness | K8s probe |
| `GET /healthz` | Application | Smoke tests |
| `GET /feature/new` | Testing | Feature flag |

## 🔍 Troubleshooting

| Issue | Solution |
|-------|----------|
| Image build fails | `docker login` and set `REG` correctly |
| Deploy timeout | Check resource availability: `kubectl top nodes` |
| Probe failures | View logs: `make logs` |
| Smoke test fails | Check Service DNS: `kubectl get svc -n test-rollback` |
| Rollback doesn't work | Check history: `make history` |

## 📖 Learning Resources

- **Kubernetes Probes:** `k8s-manifests/base/deployment.yaml` (readinessProbe section)
- **Canary Strategy:** `k8s-manifests/rollouts/rollout.yaml` (steps section)
- **Metrics Analysis:** `k8s-manifests/rollouts/analysis-template.yaml` (Prometheus query)
- **Automation:** `scripts/*.sh` (all scripts have comments)

## ✅ Checklist Before Production

- [ ] Update `REG` in Makefile to your registry
- [ ] Configure Kubernetes cluster
- [ ] Install kubectl and set context
- [ ] (Optional) Install Argo CD and Argo Rollouts
- [ ] Run `make build push set-image deploy wait smoke`
- [ ] Test failure scenario: `make fail-on && make wait && make undo`
- [ ] Review logs and metrics
- [ ] Customize resource limits for your needs
- [ ] Configure database connection string (DB_DSN)

## 🎓 Project Highlights

### What Makes This Project Complete

1. **Two Deployment Modes**
   - Simple: kubectl for basic rolling updates
   - Advanced: Argo CD + Rollouts for canary with auto-rollback

2. **Comprehensive Health Checks**
   - Liveness probe: Detects stuck containers
   - Readiness probe: Controls traffic routing
   - Application health: Validates business logic

3. **Failure Simulation**
   - Feature flag enables bugs
   - Automatic detection triggers rollback
   - Manual recovery procedures included

4. **Database Migrations**
   - Versioned migrations
   - Reversible rollback
   - Backup strategy documented

5. **Complete Automation**
   - 15+ Make targets
   - Shell scripts for all operations
   - Zero manual kubectl commands needed

## 🚀 Next Steps

1. **Read:** `cat README.md`
2. **Understand:** `cat QUICKSTART.md`
3. **Configure:** `make help` (set REG variable)
4. **Build:** `make build`
5. **Deploy:** `make deploy wait`
6. **Test:** `make smoke`
7. **Observe:** `make logs`

---

**Status:** ✅ Ready for deployment  
**Questions?** Check [README.md](README.md) or [QUICKSTART.md](QUICKSTART.md)
