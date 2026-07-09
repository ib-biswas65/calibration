$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Bypass -File "C:\Calibration\deploy-package\backup-windows.ps1"' -WorkingDirectory "C:\Calibration\deploy-package"
$trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 1)
Register-ScheduledTask -TaskName "ITE Calibration Backup" -Action $action -Trigger $trigger -Settings $settings -Description "Daily backup of ITE Calibration database and certificate volume" -RunLevel Highest -Force
Write-Host "TASK REGISTERED OK"
