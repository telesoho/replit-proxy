"""
Replit Proxy Service
====================
Allows Replit apps to access https://eco.blockchainlock.io/api/eagle-pms
through a central proxy for centralized logging and control.

Usage in Replit App:
  # Instead of calling the API directly:
  # requests.get("https://eco.blockchainlock.io/api/eagle-pms?...")

  # Call through the proxy instead:
  # requests.get("https://your-proxy-server.com/api/eagle-pms?...")

Run:
  uvicorn main:app --host 0.0.0.0 --port 8080
"""

import logging
from contextlib import asynccontextmanager
from datetime import datetime, timezone

import httpx
import uvicorn
from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse

from config import (
    PROXY_HOST,
    PROXY_PORT,
    TARGET_BASE_URL,
    TARGET_EAGLE_PMS_PATH,
    UPSTREAM_TIMEOUT_SECONDS,
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("replit-proxy")

# Application-level HTTP client (singleton) — created on startup, closed on shutdown.
# This avoids creating/destroying an AsyncClient per request, which causes memory leaks
# and file-descriptor exhaustion under sustained load.
http_client: httpx.AsyncClient | None = None


@asynccontextmanager
async def lifespan(_: FastAPI):
    global http_client
    http_client = httpx.AsyncClient(
        timeout=httpx.Timeout(UPSTREAM_TIMEOUT_SECONDS),
        limits=httpx.Limits(max_connections=100, max_keepalive_connections=20),
    )
    logger.info("HTTP client started (max_connections=100, max_keepalive=20)")
    try:
        yield
    finally:
        if http_client:
            await http_client.aclose()
            logger.info("HTTP client closed")


app = FastAPI(
    title="Replit Proxy",
    description="Central proxy for Replit apps to access external APIs",
    lifespan=lifespan,
)


@app.middleware
async def log_requests(request: Request, call_next):
    """Log every request that passes through the proxy."""
    start_time = datetime.now(timezone.utc)
    client_ip = request.headers.get("x-forwarded-for", request.client.host if request.client else "unknown")

    response = await call_next(request)

    duration = (datetime.now(timezone.utc) - start_time).total_seconds()

    # Log in structured format
    logger.info(
        "client_ip=%s method=%s path=%s status=%d duration=%.3f",
        client_ip,
        request.method,
        request.url.path,
        response.status_code,
        duration,
    )

    return response


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "ok", "service": "replit-proxy"}


@app.api_route("/api/eagle-pms/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"])
async def proxy_eagle_pms(path: str, request: Request) -> Response:
    """
    Proxy endpoint that forwards all requests to
    https://eco.blockchainlock.io/api/eagle-pms

    Replit apps should call: GET/POST /api/eagle-pms?...
    This will forward to:    GET/POST https://eco.blockchainlock.io/api/eagle-pms?...
    """
    # Build target URL
    # path is everything after /proxy/eagle-pms (could be empty or /something)
    suffix = path if path.startswith("/") else f"/{path}"
    target_url = f"{TARGET_BASE_URL}{TARGET_EAGLE_PMS_PATH}{suffix}"

    # Forward query params
    query_params = dict(request.query_params)

    # Read request body if present
    body = await request.body()

    # Collect headers to forward (filter hop-by-hop / proxy-managed headers)
    headers = dict(request.headers)
    hop_by_hop_headers = {
        "host",
        "connection",
        "transfer-encoding",
        "keep-alive",
        "proxy-connection",
        "upgrade",
        "te",
        "trailer",
        "content-length",
    }
    headers = {k: v for k, v in headers.items() if k.lower() not in hop_by_hop_headers}

    logger.info(
        "Forwarding %s %s  -->  %s",
        request.method,
        request.url.path,
        target_url,
    )

    client = http_client
    if client is None:
        logger.error("HTTP client is not initialized")
        return JSONResponse(
            status_code=503,
            content={"error": "Service unavailable: HTTP client is not initialized"},
        )

    try:
        response = await client.request(
            method=request.method,
            url=target_url,
            params=query_params,
            headers=headers,
            content=body if body else None,
            follow_redirects=True,
        )

        # Do not forward response transport headers as-is; Starlette will manage them.
        filtered_response_headers = {
            k: v
            for k, v in response.headers.items()
            if k.lower()
            not in {
                "content-length",
                "transfer-encoding",
                "connection",
                "keep-alive",
                "proxy-connection",
                "upgrade",
                "te",
                "trailer",
                "content-encoding",
            }
        }

        return Response(
            content=response.content,
            status_code=response.status_code,
            headers=filtered_response_headers,
            media_type=response.headers.get("content-type"),
        )

    except httpx.TimeoutException:
        logger.error("Timeout calling %s (timeout=%ss)", target_url, UPSTREAM_TIMEOUT_SECONDS)
        return JSONResponse(
            status_code=504,
            content={"error": "Upstream request timed out"},
        )
    except httpx.RequestError as exc:
        logger.error("Request error calling %s: %s", target_url, exc)
        return JSONResponse(
            status_code=502,
            content={"error": f"Upstream request failed: {exc}"},
        )


if __name__ == "__main__":
    uvicorn.run(app, host=PROXY_HOST, port=PROXY_PORT)
