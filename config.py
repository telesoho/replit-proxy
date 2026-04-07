"""
Configuration for the Replit Proxy service.
"""

import os
from pathlib import Path

from dotenv import load_dotenv

# Load server runtime env vars from .server.env
load_dotenv(Path(__file__).parent / ".server.env")

# Target API endpoint that all Replit apps will route through
TARGET_BASE_URL = "https://eco.blockchainlock.io"
TARGET_EAGLE_PMS_PATH = "/api/eagle-pms"

# Proxy server configuration
PROXY_HOST = os.environ.get("PROXY_HOST", "0.0.0.0")
PROXY_PORT = int(os.environ.get("PROXY_PORT", "8080"))

# Upstream timeout configuration (seconds)
UPSTREAM_TIMEOUT_SECONDS = float(os.environ.get("UPSTREAM_TIMEOUT_SECONDS", "60"))
