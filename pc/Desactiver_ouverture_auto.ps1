# Désactive l'ouverture automatique du magazine.
# Clic droit sur ce fichier -> "Exécuter avec PowerShell".
try {
  Unregister-ScheduledTask -TaskName "Tech & Cyber Daily" -Confirm:$false
  Write-Host "OK - L'ouverture automatique est desactivee." -ForegroundColor Green
} catch {
  Write-Host "Rien a desactiver (la tache n'existait pas)." -ForegroundColor Yellow
}
Write-Host "Appuie sur une touche pour fermer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
