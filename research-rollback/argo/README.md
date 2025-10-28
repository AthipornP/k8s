# Argo CD Configuration

This directory contains Argo CD Application manifests for continuous deployment and synchronization.

## Files

- **app.yaml**: Main Argo CD Application resource
  - Points to `k8s-manifests/rollouts` for Argo Rollouts deployment
  - Configured with automated sync and self-healing
  - Requires modification of `repoURL` to point to your Git repository

- **hooks/**: Deployment lifecycle hooks

  - **presync-backup.yaml**: Pre-sync hook that simulates backup operations
  - **postsync-smoke.yaml**: Post-sync hook that runs smoke tests after deployment

## Prerequisites

- Argo CD installed in the cluster (typically in `argocd` namespace)
- Repository credentials configured in Argo CD
- Project `default` exists with appropriate permissions

## Usage

### Install Application

```bash
kubectl apply -n argocd -f argo/app.yaml
```

### Trigger Sync

```bash
argocd app sync myapp
```

### View Application Status

```bash
argocd app get myapp
kubectl get application -n argocd myapp
```

### Rollback to Previous Revision

```bash
argocd app rollback myapp --to-revision 1
```

### Manual Refresh

```bash
argocd app refresh myapp
```

## Important Notes

1. **Repository URL**: Update the `repoURL` in `app.yaml` to point to your actual Git repository

2. **Git Branch**: Default uses `HEAD`. Update `targetRevision` for specific branches:
   ```yaml
   targetRevision: main    # or develop, staging, etc.
   ```

3. **Hooks**: The hook manifests simulate operations. For production:
   - Update `presync-backup.yaml` with actual backup logic
   - Configure real database snapshots if needed

4. **Automated Sync**: Currently enabled with pruning and self-healing
   - `prune: true`: Deletes resources removed from Git
   - `selfHeal: true`: Automatically syncs when drift detected

## Switching Between Modes

For **kubectl mode**: Apply manifests from `k8s-manifests/base/`
```bash
kubectl apply -n test-rollback -f k8s-manifests/base/
```

For **Argo Rollouts mode**: Use Argo CD with `k8s-manifests/rollouts/`
```bash
kubectl apply -n argocd -f argo/app.yaml
```

## Monitoring & Troubleshooting

### View Argo CD Events
```bash
kubectl get events -n argocd -l app.kubernetes.io/instance=myapp
```

### View Application Logs
```bash
argocd app logs myapp --follow
```

### Check Sync Status
```bash
argocd app wait myapp
```
