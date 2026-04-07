"""
KeyVox API client for eagle-pms endpoints.

This module handles HMAC-SHA256 signed requests to the KeyVox/eagle-pms API.
"""

import base64
import hashlib
import hmac
import json
import os
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv

import httpx

# Load .env from project root (one level up from this file)
_dotenv_path = Path(__file__).parent / ".env"
load_dotenv(_dotenv_path)

KEYVOX_BASE_URL = os.environ.get("KEYVOX_BASE_URL", "https://eco.blockchainlock.io")


def _make_digest(body_str: str) -> str:
    """Compute SHA-256 digest of request body in HTTP Digest format."""
    body_hash = hashlib.sha256(body_str.encode("utf-8")).digest()
    body_b64 = base64.b64encode(body_hash).decode("ascii")
    return f"SHA-256={body_b64}"


def _build_signing_string(method: str, path: str, digest: str, date: str) -> str:
    """Build the canonical string that gets HMAC-signed."""
    return f"date: {date}\n{method} {path} HTTP/1.1\ndigest: {digest}"


def _make_signature(signing_string: str, secret_key: str) -> str:
    """Compute HMAC-SHA256 signature and return it as base64."""
    return base64.b64encode(
        hmac.new(
            secret_key.encode("utf-8"),
            signing_string.encode("utf-8"),
            hashlib.sha256,
        ).digest()
    ).decode("ascii")


def _build_authorization(api_key: str, signature: str) -> str:
    """Build the HMAC authorization header."""
    return (
        f'hmac username="{api_key}", algorithm="hmac-sha256", '
        f'headers="date request-line digest", signature="{signature}"'
    )


def request_lock_status(
    api_key: str,
    secret_key: str,
    lock_id: str,
    target_host: str = "default.pms",
    base_url: str | None = None,
) -> httpx.Response:
    """
    Call POST /v1/getLockStatus with HMAC-SHA256 authentication.

    Args:
        api_key:       API key username
        secret_key:    HMAC secret
        lock_id:       Lock ID to query
        target_host:   x-target-host header value
        base_url:      API base URL

    Returns:
        httpx.Response from the API
    """
    method = "POST"
    path = "/v1/getLockStatus"
    url = f"{(base_url if base_url is not None else KEYVOX_BASE_URL)}{path}"

    body_str = json.dumps({"lockId": lock_id})
    digest = _make_digest(body_str)
    date = datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S GMT")
    signing_string = _build_signing_string(method, path, digest, date)
    signature = _make_signature(signing_string, secret_key)
    authorization = _build_authorization(api_key, signature)

    headers = {
        "Content-Type": "application/json",
        "x-target-host": target_host,
        "date": date,
        "digest": digest,
        "authorization": authorization,
    }

    return httpx.post(url, headers=headers, content=body_str)


if __name__ == "__main__":
    api_key = os.environ.get("KEYVOX_API_KEY", "")
    secret_key = os.environ.get("KEYVOX_SECRET_KEY", "")

    if not api_key or not secret_key:
        print("Set KEYVOX_API_KEY and KEYVOX_SECRET_KEY environment variables.")
    else:
        resp = request_lock_status(api_key, secret_key, lock_id="QROBZW5OSX2J9QMQ")
        print(f"Status: {resp.status_code}")
        print(f"Body: {resp.text}")
