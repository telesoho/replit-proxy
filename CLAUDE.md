# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Replit Proxy Service — a central proxy that all Replit apps use to access external APIs, enabling centralized logging and control.

## Development Commands

```bash
# Install dependencies (uv auto-syncs from pyproject.toml)
uv sync

# Run the proxy server
uv run uvicorn main:app --host 0.0.0.0 --port 8080

# Run with auto-reload for development
uv run uvicorn main:app --host 0.0.0.0 --port 8080 --reload

# Add a dependency
uv add httpx

# Add a dev dependency
uv add --dev pytest

# Run tests
uv run pytest

# Lint / format
uv run ruff check .
uv run ruff format .
```

## Architecture

```
Replit App  -->  /proxy/eagle-pms  -->  https://eco.blockchainlock.io/api/eagle-pms
```

- **main.py** — FastAPI application with proxy endpoint and request logging middleware
- **config.py** — Configuration for target URL and server settings
- **pyproject.toml** — Project metadata and dependencies (managed by uv)
- **scripts/** — Shell/batch scripts to run the server

## How Replit Apps Use It

Instead of calling the API directly:
```python
# Old way (bypasses proxy)
requests.get("https://eco.blockchainlock.io/api/eagle-pms?param=value")

# New way (all traffic goes through proxy)
requests.get("https://your-proxy-domain.com/proxy/eagle-pms?param=value")
```
