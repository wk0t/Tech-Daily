# Disables automatic startup of the magazine.
# Right-click this file -> "Run with PowerShell".
try {
  Unregister-ScheduledTask -TaskName "Tech & Cyber Daily" -Confirm:$false
  Write-Host "OK - Automatic startup is disabled." -ForegroundColor Green
} catch {
  Write-Host "Rien a desactiver (la tache n'existait pas)." -ForegroundColor Yellow
}
Write-Host "Appuie sur une touche pour fermer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
