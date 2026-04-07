@echo off
:: Run the Replit Proxy server

cd /d "%~dp0.."

uv run uvicorn main:app --host 0.0.0.0 --port 8080
