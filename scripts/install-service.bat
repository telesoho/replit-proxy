@echo off
setlocal

:: Replit Proxy — Windows Service Installer
:: Usage: install-service.bat
:: Requires: NSSM (Non-Sucking Service Manager) in PATH
:: Download: https://nssm.cc/download

set "SERVICE_NAME=ReplitProxy"
set "PROJECT_DIR=%~dp0.."
set "UV_EXE=uv"
set "HOST=0.0.0.0"
set "PORT=8080"

echo ========================================
echo  Replit Proxy Service Installer
echo ========================================
echo.

where nssm >nul 2>&1
if errorlevel 1 (
    echo [ERROR] NSSM not found in PATH.
    echo Please install NSSM and add its directory to PATH.
    echo Download: https://nssm.cc/download
    echo.
    echo After installing NSSM, run this script again.
    pause
    exit /b 1
)

where uv >nul 2>&1
if errorlevel 1 (
    echo [ERROR] uv not found in PATH.
    echo Please install uv: https://github.com/astral-sh/uv
    pause
    exit /b 1
)

nssm status "%SERVICE_NAME%" >nul 2>&1
if not errorlevel 1 (
    echo [INFO]  Service "%SERVICE_NAME%" already exists.
    choice /C yn /N /M "Uninstall it first? [Y/N]: "
    if errorlevel 1 (
        echo [INFO]  Stopping and removing existing service...
        nssm stop "%SERVICE_NAME%"
        nssm remove "%SERVICE_NAME%" /confirm
    ) else (
        echo [ABORT] Aborted.
        pause
        exit /b 0
    )
)

echo [INFO]  Installing service "%SERVICE_NAME%"...
nssm install "%SERVICE_NAME%" "%UV_EXE%" "run uvicorn main:app --host %HOST% --port %PORT%"
nssm set "%SERVICE_NAME%" AppDirectory "%PROJECT_DIR%"

:: Restart policy: manual by default
nssm set "%SERVICE_NAME%" Start SERVICE_DEMAND_START

:: Log rotation (10 MB max, 3 files)
nssm set "%SERVICE_NAME%" AppRotateFiles 1
nssm set "%SERVICE_NAME%" AppRotateBytes 10485760
nssm set "%SERVICE_NAME%" AppRotateOnline 1

:: Environment: load KEYVOX_BASE_URL if set
if defined KEYVOX_BASE_URL (
    nssm set "%SERVICE_NAME%" AppEnvironmentExtra "KEYVOX_BASE_URL=%KEYVOX_BASE_URL%"
)
if defined KEYVOX_API_KEY (
    nssm set "%SERVICE_NAME%" AppEnvironmentExtra "KEYVOX_API_KEY=%KEYVOX_API_KEY%"
)
if defined KEYVOX_SECRET_KEY (
    nssm set "%SERVICE_NAME%" AppEnvironmentExtra "KEYVOX_SECRET_KEY=%KEYVOX_SECRET_KEY%"
)

echo.
echo [OK]    Service "%SERVICE_NAME%" installed.
echo.
echo  To start the service:
echo    nssm start %SERVICE_NAME%
echo.
echo  To set auto-start on boot:
echo    nssm set %SERVICE_NAME% Start SERVICE_AUTO_START
echo.
pause
