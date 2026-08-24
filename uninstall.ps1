<#
.SYNOPSIS
    Safe Unified Uninstaller for VimWindows
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$StartupFolder = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupFolder "VimWindows.lnk"

Write-Host "🛑 جارٍ إيقاف منظومة VimWindows وإزالتها من بدء التشغيل..." -ForegroundColor Yellow

# Stop Mousemaster process
Get-Process -Name "mousemaster" -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    Write-Host "   ✅ تم إيقاف محرك Mousemaster (PID: $($_.Id))." -ForegroundColor Green
}

# Stop VimWindows instance
$stoppedAhk = $false
Get-CimInstance Win32_Process -Filter "Name like 'AutoHotkey%'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*vim_windows.ahk*" } | ForEach-Object { 
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue 
    Write-Host "   ✅ تم إيقاف سكريبت VimWindows (PID: $($_.ProcessId))." -ForegroundColor Green
    $stoppedAhk = $true
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
