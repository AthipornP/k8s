# MyApp - K8s Deployment & Rollback Demo

Simple HTTP server for demonstrating Kubernetes deployment, health checks, and automated rollback scenarios.

## Features

- **Liveness Probe** (`/live`): Always ready, indicates container is running
- **Readiness Probe** (`/ready`): Returns 503 until BOOT_DELAY seconds have elapsed
- **Health Check** (`/healthz`): Returns 200 if DB_DSN environment variable is configured
- **Feature Endpoint** (`/feature/new`): Tests feature flag behavior with random failures when FEATURE_NEW=true

## Environment Variables

- `BOOT_DELAY`: Seconds to wait before readiness probe passes (default: 5)
- `DB_DSN`: Database connection string (required for /healthz)
- `FEATURE_NEW`: Enable new feature with random 50% failure rate (default: false)

## Running Locally

```bash
pip install -r requirements.txt
python main.py
```

Server runs on `http://localhost:8080`

## Testing

```bash
curl http://localhost:8080/live
curl http://localhost:8080/ready
curl http://localhost:8080/healthz
curl http://localhost:8080/feature/new
```
