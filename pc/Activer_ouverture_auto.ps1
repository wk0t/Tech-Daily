# Active l'ouverture automatique du magazine chaque matin à 08:00.
# Clic droit sur ce fichier -> "Exécuter avec PowerShell".
$exe = "C:\Users\wk0t\Documents\TechCyberDaily\TechCyberDaily.exe"
try {
  $action  = New-ScheduledTaskAction -Execute $exe
  $trigger = New-ScheduledTaskTrigger -Daily -At 8:00am
  $set     = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
  Register-ScheduledTask -TaskName "Tech & Cyber Daily" -Action $action -Trigger $trigger -Settings $set -Description "Ouvre le magazine tech/cyber chaque matin" -Force | Out-Null
  Write-Host "OK - Le magazine s'ouvrira automatiquement chaque jour a 08:00 (ou au prochain allumage si le PC etait eteint)." -ForegroundColor Green
} catch {
  Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host "Appuie sur une touche pour fermer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
