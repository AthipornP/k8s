# Database Migration & Backup Strategy

## General Principles

This project uses versioned migrations with rollback support. All migrations must be reversible (expand-contract pattern).

## Pre-Migration Checklist

Before running any migration job:

1. **Backup Database**: Create a snapshot or backup of the database
   ```bash
   # Example: PostgreSQL backup
   pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Document Changes**: Record what the migration does and how to rollback

3. **Test on Staging**: Always test migrations on a staging environment first

## Migration Versioning

Migrations use versioned names: `YYYYMMDD`
- Example: `20251028` for October 28, 2025

## Job Files

- `migrator-job-up.yaml`: Runs upgrade migrations
- `migrator-job-down.yaml`: Runs rollback migrations (only reversible)

## Running Migrations

### Apply upgrade:
```bash
kubectl apply -n test-rollback -f k8s-manifests/db/migrator-job-up.yaml
kubectl wait --for=condition=complete job/db-migrator-up -n test-rollback --timeout=5m
```

### Rollback (if reversible):
```bash
kubectl apply -n test-rollback -f k8s-manifests/db/migrator-job-down.yaml
kubectl wait --for=condition=complete job/db-migrator-down -n test-rollback --timeout=5m
```

## Notes

- Only **reversible** migrations should have a `migrator-job-down.yaml`
- For destructive migrations, only backup/restore is supported
- Consider using the expand-contract pattern for zero-downtime deployments
- Always snapshot data before major version upgrades

## Post-Migration

1. Verify application health
2. Check logs for errors
3. Run smoke tests
4. Monitor metrics
