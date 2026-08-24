@echo off
setlocal
title VimWindows Uninstaller
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
