@echo off
setlocal
title VimWindows Installer
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Press any key to exit...
    pause >nul
)
