# Opens the magazine automatically every morning at 08:00.
# Right-click this file -> "Run with PowerShell".
$exe = "C:\Users\wk0t\Documents\TechCyberDaily\TechCyberDaily.exe"
try {
  $action  = New-ScheduledTaskAction -Execute $exe
  $trigger = New-ScheduledTaskTrigger -Daily -At 8:00am
  $set     = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
  Register-ScheduledTask -TaskName "Tech & Cyber Daily" -Action $action -Trigger $trigger -Settings $set -Description "Opens the tech/cyber magazine every morning" -Force | Out-Null
  Write-Host "OK - The magazine will open automatically every day at 08:00 (or at next startup if the PC was off)." -ForegroundColor Green
} catch {
  Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host "Appuie sur une touche pour fermer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
