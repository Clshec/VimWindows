<#
.SYNOPSIS
    Smart Native Installer for VimWindows
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "VimWindows Installer"

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "          🟢 VimWindows - مثبت الإعداد الذكي             " -ForegroundColor Green
Write-Host "         Native 1-Click Installer for Windows            " -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AhkScript = Join-Path $ScriptDir "vim_windows.ahk"
$StartupFolder = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupFolder "VimWindows.lnk"

# 1. Check/Install AutoHotkey v2
Write-Host "[1/3] 🔍 فحص وجود برنامج AutoHotkey v2..." -ForegroundColor Yellow

$AhkExe = $null
$PossiblePaths = @(
    "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe",
    "C:\Program Files\AutoHotkey\v2\AutoHotkey32.exe",
    "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey32.exe"
)

foreach ($path in $PossiblePaths) {
    if (Test-Path $path) {
        $AhkExe = $path
        break
    }
}

if (-not $AhkExe) {
    $inPath = Get-Command "AutoHotkey64.exe", "AutoHotkey.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($inPath) {
        $AhkExe = $inPath.Source
    }
}

if ($AhkExe) {
    Write-Host "   ✅ تم العثور على AutoHotkey v2 في: $AhkExe" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ AutoHotkey v2 غير مثبت. جارٍ التثبيت التلقائي..." -ForegroundColor Yellow
    
    $hasWinget = Get-Command "winget" -ErrorAction SilentlyContinue
    $installed = $false

    if ($hasWinget) {
        Write-Host "   📦 جارٍ التثبيت عبر Windows Package Manager (winget)..." -ForegroundColor Cyan
        Start-Process -FilePath "winget" -ArgumentList "install --id AutoHotkey.AutoHotkey --source winget --silent --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
        
        foreach ($path in $PossiblePaths) {
            if (Test-Path $path) {
                $AhkExe = $path
                $installed = $true
                break
            }
        }
    }

    if (-not $installed) {
        Write-Host "   🌐 تحميل AutoHotkey v2 من الموقع الرسمي..." -ForegroundColor Cyan
        $installerUrl = "https://www.autohotkey.com/download/ahk-v2.exe"
        $installerPath = Join-Path $env:TEMP "ahk-v2-setup.exe"
        
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
            Write-Host "   ⚡ تشغيل المثبت في الوضع الصامت..." -ForegroundColor Cyan
            Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
            
            foreach ($path in $PossiblePaths) {
                if (Test-Path $path) {
                    $AhkExe = $path
                    $installed = $true
                    break
                }
            }
        } catch {
            Write-Host "   ❌ تعذر التحميل التلقائي لـ AutoHotkey: $_" -ForegroundColor Red
        }
    }

    if (-not $AhkExe) {
        Write-Host "   ❌ يرجى تثبيت AutoHotkey v2 يدوياً من https://www.autohotkey.com/" -ForegroundColor Red
        Pause
        exit 1
    }
    Write-Host "   ✅ تم تثبيت AutoHotkey v2 بنجاح!" -ForegroundColor Green
}

# 2. Add to Windows Startup
Write-Host "[2/3] ⚙️ إضافة السكريبت لبدء التشغيل التلقائي مع ويندوز (Startup)..." -ForegroundColor Yellow
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $AhkExe
    $Shortcut.Arguments = "`"$AhkScript`""
    $Shortcut.WorkingDirectory = $ScriptDir
    $Shortcut.Description = "VimWindows - Native Vim Navigation & Mouse Engine"
    $Shortcut.Save()
    Write-Host "   ✅ تم تفعيل التشغيل التلقائي مع تشغيل الجهاز بنجاح!" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ تعذر إنشاء اختصار بدء التشغيل: $_" -ForegroundColor DarkYellow
}

# 3. Launch Script Safely
Write-Host "[3/3] 🚀 تشغيل منظومة VimWindows المتكاملة..." -ForegroundColor Yellow

# Stop previous instance of vim_windows.ahk
Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*vim_windows.ahk*" } | ForEach-Object { 
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue 
}
Start-Sleep -Milliseconds 300

Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "`"$AhkExe`" `"$AhkScript`"" } | Out-Null
Write-Host "   ✅ تم تشغيل سكريبت VimWindows بنجاح." -ForegroundColor Green

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  🎉 تم تثبيت وتشغيل VimWindows بنجاح!                   " -ForegroundColor White
Write-Host "  👉 اضغط Home أو Ctrl + Win لتفعيل NORMAL MODE           " -ForegroundColor Yellow
Write-Host "  👉 اضغط CapsLock لتبديل لغة الإدخال بنقرة واحدة (عربي/إنجليزي)" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 3
