.PHONY: help build push set-image deploy wait smoke logs history undo fail-on fail-off clean argo-app argo-sync argo-rollback

# Configuration
REG ?= registry.local
IMG ?= $(REG)/myapp
TAG ?= $(shell date +%Y%m%d).1
NS  ?= test-rollback

help:
	@echo "=== MyApp K8s Deployment Makefile ==="
	@echo ""
	@echo "Configuration:"
	@echo "  REG  = $(REG)  (registry)"
	@echo "  IMG  = $(IMG)  (image name)"
	@echo "  TAG  = $(TAG)  (current tag)"
	@echo "  NS   = $(NS)   (namespace)"
	@echo ""
	@echo "Targets:"
	@echo ""
	@echo "Container:"
	@echo "  make build        - Build Docker image"
	@echo "  make push         - Push image to registry"
	@echo ""
	@echo "kubectl mode (Base Deployment):"
	@echo "  make set-image    - Update manifest image tags"
	@echo "  make deploy       - Apply manifests (base)"
	@echo "  make wait         - Wait for rollout to complete"
	@echo "  make smoke        - Run smoke tests"
	@echo "  make logs         - Tail deployment logs"
	@echo "  make history      - Show rollout history"
	@echo "  make undo         - Rollback to previous revision"
	@echo ""
	@echo "Feature testing:"
	@echo "  make fail-on      - Enable feature flag (trigger failures)"
	@echo "  make fail-off     - Disable feature flag (restore stable)"
	@echo ""
	@echo "Argo CD mode (Rollouts):"
	@echo "  make argo-app     - Create Argo CD application"
	@echo "  make argo-sync    - Sync application"
	@echo "  make argo-rollback - Rollback to previous revision"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean        - Delete all resources"
	@echo ""
	@echo "Quick start:"
	@echo "  make build push set-image deploy wait smoke"
	@echo ""

# ============================================================================
# Container Build & Push
# ============================================================================

build:
	@echo "Building image: $(IMG):$(TAG)"
	bash scripts/build.sh $(IMG) $(TAG)

push:
	@echo "Pushing image: $(IMG):$(TAG)"
	bash scripts/push.sh $(IMG) $(TAG)

# ============================================================================
# kubectl Mode - Base Deployment
# ============================================================================

set-image:
	@echo "Setting image tag to: $(TAG)"
	bash scripts/set-image.sh $(TAG)

deploy:
	@echo "Deploying to namespace: $(NS)"
	kubectl apply -n $(NS) -f k8s-manifests/base/

wait:
	@echo "Waiting for rollout to complete..."
	kubectl rollout status deployment/myapp -n $(NS) --timeout=5m

smoke:
	@echo "Running smoke tests..."
	bash scripts/run-smoke.sh $(NS)

logs:
	@echo "Tailing deployment logs..."
	kubectl logs -n $(NS) deploy/myapp --all-containers=true --tail=200 -f

history:
	@echo "Rollout history:"
	kubectl rollout history deployment/myapp -n $(NS)

undo:
	@echo "Rolling back to previous revision..."
	kubectl rollout undo deployment/myapp -n $(NS)
	kubectl rollout status deployment/myapp -n $(NS) --timeout=5m

# ============================================================================
# Feature Testing
# ============================================================================

fail-on:
	@echo "Enabling new feature (will cause failures)..."
	bash scripts/gen-failure.sh $(NS)

fail-off:
	@echo "Disabling new feature (restore stable)..."
	bash scripts/restore-config.sh $(NS)

# ============================================================================
# Argo CD Mode - Rollouts Deployment
# ============================================================================

argo-app:
	@echo "Creating Argo CD application in namespace argocd..."
	kubectl apply -n argocd -f argo/app.yaml

argo-sync:
	@echo "Syncing Argo CD application..."
	argocd app sync myapp --wait

argo-rollback:
	@echo "Rolling back Argo CD application to previous revision..."
	argocd app rollback myapp --to-revision 1
	argocd app wait myapp

# ============================================================================
# Cleanup
# ============================================================================

clean:
	@echo "Deleting all resources from namespace $(NS)..."
	kubectl delete namespace $(NS) --ignore-not-found=true
	@echo "Resources cleaned up"

# ============================================================================
# Shortcuts for quick workflows
# ============================================================================

# Full deployment flow
.PHONY: full-deploy
full-deploy: build push set-image deploy wait smoke
	@echo "✓ Full deployment completed successfully"

# Full test flow (include failure scenario)
.PHONY: full-test
full-test: full-deploy fail-on wait fail-off
	@echo "✓ Full test flow completed"
