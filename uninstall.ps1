<#
.SYNOPSIS
    Safe Uninstaller for VimWindows
    Stops only VimWindows processes and removes startup shortcut.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$StartupFolder = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupFolder "VimWindows.lnk"

Write-Host "🛑 جارٍ إيقاف سكريبت VimWindows وإزالته من بدء التشغيل..." -ForegroundColor Yellow

# Stop ONLY VimWindows instances safely without affecting other AHK scripts
$stopped = $false
Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*vim_windows.ahk*" } | ForEach-Object { 
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue 
    Write-Host "   ✅ تم إيقاف عملية VimWindows (PID: $($_.ProcessId))." -ForegroundColor Green
    $stopped = $true
}

if (-not $stopped) {
    Write-Host "   ℹ️ لم تكن هناك عملية نشطة لـ VimWindows." -ForegroundColor Cyan
}

# Remove startup shortcut
if (Test-Path $ShortcutPath) {
    Remove-Item $ShortcutPath -Force
    Write-Host "✅ تم حذف اختصار بدء التشغيل التلقائي بنجاح." -ForegroundColor Green
} else {
    Write-Host "ℹ️ لم يتم العثور على اختصار بدء تشغيل." -ForegroundColor Cyan
}

Write-Host "✅ تم إلغاء التثبيت بنجاح." -ForegroundColor Green
Start-Sleep -Seconds 2
