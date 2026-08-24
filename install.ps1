<#
.SYNOPSIS
    Smart Installer for VimWindows
    Automatically detects/installs AutoHotkey v2, creates startup shortcuts, and launches the script.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "VimWindows Smart Installer"

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "       🟢 VimWindows - مثبت الإعداد الذكي التلقائي        " -ForegroundColor Green
Write-Host "         Smart 1-Click Installer for Windows             " -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AhkScript = Join-Path $ScriptDir "vim_windows.ahk"
$StartupFolder = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupFolder "VimWindows.lnk"

# 1. Check if AutoHotkey v2 is installed
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
    
    # Try winget first
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
        Write-Host "   🌐 جارٍ تحميل مثبت AutoHotkey v2 الرسمي مباشرة..." -ForegroundColor Cyan
        $InstallerUrl = "https://www.autohotkey.com/download/ahk-v2.exe"
        $TempInstaller = Join-Path $env:TEMP "ahk-v2-setup.exe"
        
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $InstallerUrl -OutFile $TempInstaller -UseBasicParsing
            Write-Host "   ⚙️ جارٍ تثبيت AutoHotkey v2 في الخلفية..." -ForegroundColor Cyan
            Start-Process -FilePath $TempInstaller -ArgumentList "/silent" -Wait
            Start-Sleep -Seconds 2
            
            foreach ($path in $PossiblePaths) {
                if (Test-Path $path) {
                    $AhkExe = $path
                    $installed = $true
                    break
                }
            }
        } catch {
            Write-Host "   ❌ تعذر التحميل التلقائي: $_" -ForegroundColor Red
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
    $Shortcut.Description = "VimWindows - System-wide Vimium Keyboard Navigation"
    $Shortcut.Save()
    Write-Host "   ✅ تم تفعيل التشغيل التلقائي مع تشغيل الجهاز بنجاح!" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ تعذر إنشاء اختصار بدء التشغيل: $_" -ForegroundColor DarkYellow
}

# 3. Launch Script Immediately
Write-Host "[3/3] 🚀 تشغيل السكريبت فوراً..." -ForegroundColor Yellow
Stop-Process -Name "AutoHotkey64", "AutoHotkey32" -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "`"$AhkExe`" `"$AhkScript`"" } | Out-Null

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  🎉 تم التثبيت والتشغيل بنجاح!                          " -ForegroundColor White
Write-Host "  👉 اضغط Ctrl + Win في أي وقت لتفعيل NORMAL MODE        " -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 3
