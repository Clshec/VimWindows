@echo off
setlocal
title VimWindows Launcher

REM Check 64-bit default location
if exist "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" (
    start "" "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "%~dp0vim_windows.ahk"
    exit
)

REM Check 32-bit location
if exist "C:\Program Files\AutoHotkey\v2\AutoHotkey32.exe" (
    start "" "C:\Program Files\AutoHotkey\v2\AutoHotkey32.exe" "%~dp0vim_windows.ahk"
    exit
)

REM Check local AppData location
if exist "%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe" (
    start "" "%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe" "%~dp0vim_windows.ahk"
    exit
)

REM Try running directly if in PATH
where AutoHotkey64.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    start "" AutoHotkey64.exe "%~dp0vim_windows.ahk"
    exit
)

where AutoHotkey.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    start "" AutoHotkey.exe "%~dp0vim_windows.ahk"
    exit
)

echo [ERROR] AutoHotkey v2 was not found on your system!
echo Please download and install AutoHotkey v2 from: https://www.autohotkey.com/
pause
