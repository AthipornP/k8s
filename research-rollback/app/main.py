#!/usr/bin/env python3
"""
Simple health check HTTP server for K8s deployment and rollback demonstration.
Exposes endpoints for liveness, readiness, health, and feature testing.
"""

import os
import time
import random
from fastapi import FastAPI, HTTPException
from fastapi.responses import PlainTextResponse
import uvicorn

# Initialize FastAPI app
app = FastAPI(title="myapp")

# Track startup time for BOOT_DELAY simulation
STARTUP_TIME = time.time()

# Load environment variables
BOOT_DELAY = int(os.getenv("BOOT_DELAY", "5"))
DB_DSN = os.getenv("DB_DSN", "")
FEATURE_NEW = os.getenv("FEATURE_NEW", "false").lower() == "true"


@app.get("/live", response_class=PlainTextResponse)
async def liveness():
    """
    Liveness probe: Returns 200 immediately.
    Indicates the container is running.
    """
    return "OK"


@app.get("/ready", response_class=PlainTextResponse)
async def readiness():
    """
    Readiness probe: Returns 200 after BOOT_DELAY seconds.
    Indicates the container is ready to accept traffic.
    """
    elapsed = time.time() - STARTUP_TIME
    if elapsed < BOOT_DELAY:
        raise HTTPException(status_code=503, detail="Still booting up")
    return "Ready"


@app.get("/healthz", response_class=PlainTextResponse)
async def health():
    """
    Health check: Returns 200 if DB_DSN is set.
    Simulates database connectivity check.
    """
    if not DB_DSN:
        raise HTTPException(status_code=500, detail="DB_DSN not configured")
    return "Healthy"


@app.get("/feature/new", response_class=PlainTextResponse)
async def feature_new():
    """
    Feature endpoint: Demonstrates new feature flag behavior.
    If FEATURE_NEW=true, randomly returns 500 errors (50% failure rate).
    This simulates a buggy feature rollout.
    """
    if FEATURE_NEW:
        # Simulate random failures in new feature
        if random.random() < 0.5:
            raise HTTPException(status_code=500, detail="Feature failed")
        return "Feature works"
    return "Feature disabled"


@app.get("/", response_class=PlainTextResponse)
async def root():
    """Root endpoint for basic connectivity test."""
    return "myapp is running"


if __name__ == "__main__":
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8080,
        log_level="info"
    )
