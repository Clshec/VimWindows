<#
.SYNOPSIS
    Uninstaller for VimWindows
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "VimWindows Uninstaller"

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "       🛑 VimWindows - برنامج إزالة التثبيت الآمن        " -ForegroundColor Red
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

$StartupFolder = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupFolder "VimWindows.lnk"

# 1. Stop background process
Write-Host "[1/2] 🛑 إيقاف العمليات المشغلة لـ VimWindows فقط بأمان..." -ForegroundColor Yellow

Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*vim_windows.ahk*" } | ForEach-Object { 
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue 
    Write-Host "   ✅ تم إيقاف عملية VimWindows (PID: $($_.ProcessId))." -ForegroundColor Green
}

# 2. Remove Startup Shortcut
Write-Host "[2/2] 🗑️ إزالة اختصار بدء التشغيل التلقائي (Startup)..." -ForegroundColor Yellow
if (Test-Path $ShortcutPath) {
    Remove-Item -Path $ShortcutPath -Force
    Write-Host "   ✅ تم حذف الاختصار من بدء التشغيل بنجاح." -ForegroundColor Green
} else {
    Write-Host "   ℹ️ لم يتم العثور على اختصار في بدء التشغيل." -ForegroundColor Gray
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "  ✅ تمت إزالة تشغيل VimWindows بنجاح دون المساس بأي برامج أخرى." -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 3
