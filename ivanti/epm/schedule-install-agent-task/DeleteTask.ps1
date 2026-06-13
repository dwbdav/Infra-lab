# Define the task name
$taskName = "IvantiInstallAtStartup"

# Define log file path
$logFile = "C:\Windows\Temp\TaskRemoval.log"

# Function to log messages to both console and log file
function Write-Log {
    param([string]$message)
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timeStamp - $message"
    
    # Write to console
    Write-Output $logMessage
    
    # Append to log file
    Add-Content -Path $logFile -Value $logMessage -Encoding UTF8
}

# Check if the scheduled task exists
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Log "Task '$taskName' found. Deleting..."
    
    # Remove the task
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false

    # Verify deletion
    if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
        Write-Log "Task '$taskName' successfully deleted."
    } else {
        Write-Log "ERROR: Task '$taskName' could not be deleted."
    }
} else {
    Write-Log "Task '$taskName' does not exist. No action needed."
}

Write-Log "Task removal script completed."
