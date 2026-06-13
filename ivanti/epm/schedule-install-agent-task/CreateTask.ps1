<#
.SYNOPSIS
  Copies InstallIvantiAgent.ps1 to C:\Windows\Temp and creates a scheduled task to run it at startup with a small delay.

.DESCRIPTION
  1) Detects the script directory using $PSScriptRoot.
  2) Copies InstallIvantiAgent.ps1 to C:\Windows\Temp.
  3) Creates a scheduled task that runs at startup with a 2-minute delay.
#>

# 1) Define script paths
$localScript = Join-Path -Path $PSScriptRoot -ChildPath "InstallIvantiAgent.ps1"
$destination = "C:\Windows\Temp\InstallIvantiAgent.ps1"

# 2) Copy script to C:\Windows\Temp
Write-Host "Copying InstallIvantiAgent.ps1 to $destination"
Copy-Item -Path $localScript -Destination $destination -Force

# 3) Define the scheduled task name
$taskName = "IvantiInstallAtStartup"

Write-Host "Creating scheduled task '$taskName' to run at startup with a delay..."

# 4) Define the action: Run the script silently with PowerShell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$destination`""

# 5) Run as SYSTEM with highest privileges
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest

# 6) Trigger: Run at startup with a 2-minute delay
# Définir une valeur aléatoire entre 2 et 59 minutes
$randomDelay = Get-Random -Minimum 2 -Maximum 60

# Convertir en format ISO 8601 (PTXM)
$delayString = "PT${randomDelay}M"

# Créer le déclencheur avec un délai aléatoire
$trigger = New-ScheduledTaskTrigger -AtStartup
$trigger.Delay = $delayString  # Appliquer le délai aléatoire

# 7) Check if the task already exists and remove it before creating a new one
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Host "Task '$taskName' already exists. Deleting it..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# 8) Create and register the scheduled task
$scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
Register-ScheduledTask -TaskName $taskName -InputObject $scheduledTask | Out-Null

Write-Host "Scheduled task '$taskName' created successfully. It will run at startup with a 2-minute delay."
