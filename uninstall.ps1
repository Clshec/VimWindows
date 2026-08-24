<#
.SYNOPSIS
    Uninstaller for VimWindows
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$StartupFolder = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupFolder "VimWindows.lnk"

Write-Host "🛑 جارٍ إيقاف سكريبت VimWindows وإزالته من بدء التشغيل..." -ForegroundColor Yellow

# Stop running process
Stop-Process -Name "AutoHotkey64", "AutoHotkey32" -Force -ErrorAction SilentlyContinue

# Remove startup shortcut
if (Test-Path $ShortcutPath) {
    Remove-Item $ShortcutPath -Force
    Write-Host "✅ تم حذف اختصار بدء التشغيل التلقائي بنجاح." -ForegroundColor Green
} else {
    Write-Host "ℹ️ لم يتم العثور على اختصار بدء تشغيل." -ForegroundColor Cyan
}

Write-Host "✅ تم إلغاء التثبيت بنجاح." -ForegroundColor Green
Start-Sleep -Seconds 2
