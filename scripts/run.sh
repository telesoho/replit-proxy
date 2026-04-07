#!/bin/bash
# Run the Replit Proxy server

set -e

cd "$(dirname "$0")/.."

uv run uvicorn main:app --host 0.0.0.0 --port 8080
