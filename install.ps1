<#
.SYNOPSIS
    Smart Unified Installer for VimWindows (with Mousemaster Backend)
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "VimWindows Unified Installer"

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "       🟢 VimWindows - مثبت الإعداد الذكي الموحد         " -ForegroundColor Green
Write-Host "         Unified 1-Click Installer for Windows           " -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AhkScript = Join-Path $ScriptDir "vim_windows.ahk"
$MmDir = Join-Path $ScriptDir "mousemaster"
$MmExe = Join-Path $MmDir "mousemaster.exe"
$StartupFolder = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupFolder "VimWindows.lnk"

# 1. Check/Install AutoHotkey v2
Write-Host "[1/4] 🔍 فحص وجود برنامج AutoHotkey v2..." -ForegroundColor Yellow

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

# 2. Check/Download Mousemaster Engine
Write-Host "[2/4] 🖱️ فحص محرك التحكم بالماوس المتقدم (Mousemaster Backend)..." -ForegroundColor Yellow
if (-not (Test-Path $MmDir)) {
    New-Item -ItemType Directory -Path $MmDir -Force | Out-Null
}

if (Test-Path $MmExe) {
    Write-Host "   ✅ تم العثور على محرك Mousemaster." -ForegroundColor Green
} else {
    Write-Host "   🌐 جارٍ تحميل محرك Mousemaster تلقائياً من GitHub..." -ForegroundColor Cyan
    $MmUrl = "https://github.com/petoncle/mousemaster/releases/latest/download/mousemaster.exe"
    
    $downloaded = $false
    $hasCurl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($hasCurl) {
        Write-Host "   ⚡ استخدام curl للتحميل السريع..." -ForegroundColor Cyan
        Start-Process -FilePath "curl.exe" -ArgumentList "-L `"$MmUrl`" -o `"$MmExe`"" -Wait -NoNewWindow
        if (Test-Path $MmExe) {
            $downloaded = $true
        }
    }

    if (-not $downloaded) {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $MmUrl -OutFile $MmExe -UseBasicParsing
            $downloaded = $true
        } catch {
            Write-Host "   ⚠️ تعذر التحميل عبر WebRequest: $_" -ForegroundColor DarkYellow
        }
    }

    if ($downloaded -and (Test-Path $MmExe)) {
        Write-Host "   ✅ تم تحميل محرك Mousemaster بنجاح!" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ سيتم الاعتماد على محرك الماوس المدمج في حال تعذر تشغيل Mousemaster." -ForegroundColor DarkYellow
    }
}

# 3. Add to Windows Startup
Write-Host "[3/4] ⚙️ إضافة السكريبت لبدء التشغيل التلقائي مع ويندوز (Startup)..." -ForegroundColor Yellow
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $AhkExe
    $Shortcut.Arguments = "`"$AhkScript`""
    $Shortcut.WorkingDirectory = $ScriptDir
    $Shortcut.Description = "VimWindows - Unified Vim Navigation & Mouse Backend"
    $Shortcut.Save()
    Write-Host "   ✅ تم تفعيل التشغيل التلقائي مع تشغيل الجهاز بنجاح!" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ تعذر إنشاء اختصار بدء التشغيل: $_" -ForegroundColor DarkYellow
}

# 4. Launch Services Safely
Write-Host "[4/4] 🚀 تشغيل منظومة VimWindows المتكاملة..." -ForegroundColor Yellow

# Launch Mousemaster if present
if (Test-Path $MmExe) {
    Get-Process -Name "mousemaster" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 200
    Start-Process -FilePath $MmExe -WorkingDirectory $MmDir -WindowStyle Hidden
    Write-Host "   ✅ تم تشغيل محرك Mousemaster في الخلفية." -ForegroundColor Green
}

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
Write-Host "  👉 اضغط Home أو Ctrl + Win في أي وقت لتفعيل NORMAL MODE " -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 3
