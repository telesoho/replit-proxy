@echo off
setlocal

set "SERVICE_NAME=ReplitProxy"

echo ========================================
echo  Replit Proxy Service Remover
echo ========================================
echo.

nssm status "%SERVICE_NAME%" >nul 2>&1
if errorlevel 1 (
    echo [INFO]  Service "%SERVICE_NAME%" is not installed.
    pause
    exit /b 0
)

choice /C yn /N /M "Remove service '%SERVICE_NAME%'? [Y/N]: "
if errorlevel 2 (
    echo [ABORT] Aborted.
    pause
    exit /b 0
)

echo [INFO]  Stopping service...
nssm stop "%SERVICE_NAME%"
echo [INFO]  Removing service...
nssm remove "%SERVICE_NAME%" /confirm

echo.
echo [OK]    Service "%SERVICE_NAME%" removed.
pause
