@echo off
setlocal

set "SERVICE_NAME=ReplitProxy"

if "%~1"=="" goto usage
if /i "%~1"=="start"   goto start
if /i "%~1"=="stop"    goto stop
if /i "%~1"=="restart" goto restart
if /i "%~1"=="status"  goto status
goto usage

:start
    nssm start "%SERVICE_NAME%"
    goto :eof

:stop
    nssm stop "%SERVICE_NAME%"
    goto :eof

:restart
    nssm restart "%SERVICE_NAME%"
    goto :eof

:status
    nssm status "%SERVICE_NAME%"
    goto :eof

:usage
    echo Usage: service.bat [start^|stop^|restart^|status]
    exit /b 1
