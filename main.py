"""
Replit Proxy Service
====================
Allows Replit apps to access https://eco.blockchainlock.io/api/eagle-pms
through a central proxy for centralized logging and control.

Usage in Replit App:
  # Instead of calling the API directly:
  # requests.get("https://eco.blockchainlock.io/api/eagle-pms?...")

  # Call through the proxy instead:
  # requests.get("https://your-proxy-server.com/proxy/eagle-pms?...")

Run:
  uvicorn main:app --host 0.0.0.0 --port 8080
"""

import logging
from datetime import datetime
from typing import Any

import httpx
from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse

from config import TARGET_BASE_URL, TARGET_EAGLE_PMS_PATH

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(client_ip)s | %(method)s %(path)s | %(status)d | %(duration)ds",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("replit-proxy")

app = FastAPI(title="Replit Proxy", description="Central proxy for Replit apps to access external APIs")


@app.middleware
async def log_requests(request: Request, call_next):
    """Log every request that passes through the proxy."""
    start_time = datetime.utcnow()
    client_ip = request.headers.get("x-forwarded-for", request.client.host if request.client else "unknown")

    response = await call_next(request)

    duration = (datetime.utcnow() - start_time).total_seconds()

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


@app.api_route("/proxy/eagle-pms{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"])
async def proxy_eagle_pms(path: str, request: Request) -> Response:
    """
    Proxy endpoint that forwards all requests to
    https://eco.blockchainlock.io/api/eagle-pms

    Replit apps should call: GET/POST /proxy/eagle-pms?...
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

    # Collect headers to forward (optionally filter sensitive ones)
    headers = dict(request.headers)
    hop_by_hop_headers = {"host", "connection", "transfer-encoding", "keep-alive"}
    headers = {k: v for k, v in headers.items() if k.lower() not in hop_by_hop_headers}

    logger.info(
        "Forwarding %s %s  -->  %s",
        request.method,
        request.url.path,
        target_url,
    )

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.request(
                method=request.method,
                url=target_url,
                params=query_params,
                headers=headers,
                content=body if body else None,
                follow_redirects=True,
            )

        return Response(
            content=response.content,
            status_code=response.status_code,
            headers=dict(response.headers),
            media_type=response.headers.get("content-type"),
        )

    except httpx.TimeoutException:
        logger.error("Timeout calling %s", target_url)
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
    import uvicorn
    from config import PROXY_HOST, PROXY_PORT

    uvicorn.run(app, host=PROXY_HOST, port=PROXY_PORT)
