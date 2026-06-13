$StrComputer = $env:COMPUTERNAME
$baseUrl = "http://epm2024.monlab.lan/share/ivanti/agent/"
$fileNames = @(
    "d3873a1c.0",
    "EPM_Manifest",
    "EPMAgentInstaller.exe",
    "EPM2024Agent.txt"
)
$hostName = "epm2024.monlab.lan"
$ports = @(80, 443, 9593, 9594, 9595)
$destinationFolder = "C:\Windows\Temp\EBA"
$logFile = "C:\Windows\Temp\IvantiAgentInstall.log"

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

# Check if curl.exe is available in C:\Windows\System32
$useCurlExe = Test-Path -Path "C:\Windows\System32\curl.exe"

if ($useCurlExe) {
    Write-Log "$StrComputer : Using curl.exe for file downloads"
} else {
    Write-Log "$StrComputer : curl.exe not found, defaulting to Invoke-WebRequest for file downloads"
}

# Test DNS resolution
try {
    $dnsResolution = Test-Connection -ComputerName $hostName -Count 1 -ErrorAction Stop
    Write-Log "$StrComputer : DNS resolution for $hostName succeeded. IP Address: $($dnsResolution.IPV4Address.IPAddressToString)"
} catch {
    Write-Log "$StrComputer : ERROR - DNS resolution for $hostName failed: $_"
    exit 1  # Exit the script if DNS resolution fails
}

# Test TCP port connectivity for specified ports
foreach ($port in $ports) {
    $tcpTest = Test-NetConnection -ComputerName $hostName -Port $port
    if ($tcpTest.TcpTestSucceeded) {
        Write-Log "$StrComputer : TCP connection to $hostName on port $port succeeded"
    } else {
        Write-Log "$StrComputer : ERROR - TCP connection to $hostName on port $port failed"
    }
}

# Silent creation of the systools directory for NoStopService.log
$systemToolsDir = "$Env:SystemDrive\systools"
if (!(Test-Path -Path $systemToolsDir)) {
    New-Item -Path $systemToolsDir -ItemType Directory -Force | Out-Null
}

# Silent creation of the NoStopService.log file
$logFilePath = Join-Path -Path $systemToolsDir -ChildPath "NoStopService.log"
New-Item -Path $logFilePath -ItemType File -Force | Out-Null

$ServiceName1 = "IVANTI EPM Agent Update Service"
$ServiceName2 = "Ivanti Management Agent"
$ServiceName3 = "Ivanti Software Monitoring Service"
$ServiceName4 = "Ivanti Targeted Multicast"

$service1 = Get-Service -Name $ServiceName1 -ErrorAction SilentlyContinue
$service2 = Get-Service -Name $ServiceName2 -ErrorAction SilentlyContinue
$service3 = Get-Service -Name $ServiceName3 -ErrorAction SilentlyContinue
$service4 = Get-Service -Name $ServiceName4 -ErrorAction SilentlyContinue

Write-Log "$StrComputer : $ServiceName1 Status - $($service1.Status)"
Write-Log "$StrComputer : $ServiceName2 Status - $($service2.Status)"
Write-Log "$StrComputer : $ServiceName3 Status - $($service3.Status)"
Write-Log "$StrComputer : $ServiceName4 Status - $($service4.Status)"

if ($service1.Status -eq "Running") {
    Write-Log "$StrComputer : $ServiceName1 is already running."
} Else {
    
    # Delete the folder if it exists, then recreate it
    if (Test-Path -Path $destinationFolder) {
        try {
            Remove-Item -Path $destinationFolder -Recurse -Force
            Write-Log "$StrComputer : Deleted existing folder $destinationFolder"
        } catch {
            Write-Log "$StrComputer : ERROR - Failed to delete $destinationFolder : $_"
        }
    }    
    
    # Create the folder
    if (!(Test-Path -Path $destinationFolder)) {
        New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
        Write-Log "$StrComputer : Created folder $destinationFolder"
    }
    
    # Download each file
    foreach ($fileName in $fileNames) {
        $fileUrl = $baseUrl + $fileName
        $destinationPath = Join-Path -Path $destinationFolder -ChildPath $fileName
        
        try {
            if ($useCurlExe) {
                & "C:\Windows\System32\curl.exe" -k -L -o "$destinationPath" "$fileUrl" > $null 2>&1
                Write-Log "$StrComputer : Downloaded $fileName to $destinationPath using curl.exe"
            } else {
                Invoke-WebRequest -Uri $fileUrl -OutFile $destinationPath -UseBasicParsing
                Write-Log "$StrComputer : Downloaded $fileName to $destinationPath using Invoke-WebRequest"
            }
        } catch {
            Write-Log "$StrComputer : ERROR - Failed to download $fileName from $fileUrl : $_"
        }
    }
    
    # Display downloaded files
    Write-Log "$StrComputer : Listing downloaded files with sizes in $destinationFolder"
    Get-ChildItem -Path $destinationFolder | ForEach-Object {
        Write-Log "$StrComputer : Downloaded File $destinationFolder : $($_.Name), Size: $($_.Length) bytes"
    }

    # Execute installer
    $installerPath = Join-Path -Path $destinationFolder -ChildPath "EPMAgentInstaller.exe"
    Write-Log "$StrComputer : Preparing to execute $installerPath"
    
    if (Test-Path -Path $installerPath) {
        $process = Start-Process -FilePath $installerPath -Wait -WorkingDirectory $destinationFolder -PassThru
        $exitCode = $process.ExitCode
        Write-Log "$StrComputer : Execution of $installerPath completed with exit code $exitCode"
    
        if ($exitCode -ne 0) {
            Write-Log "$StrComputer : ERROR - $installerPath failed with exit code $exitCode"
        } else {
            Write-Log "$StrComputer : $installerPath executed successfully."
        }
    } else {
        Write-Log "$StrComputer : ERROR - Installer not found at $installerPath"
    }
}

# Wait for the required "IVANTI" services to start
$timeout2 = [datetime]::Now.AddMinutes(15)
$requiredServiceCount = 4

Write-Log "$StrComputer : Waiting for 4 services starting with 'IVANTI'"

while (([datetime]::Now -lt $timeout2) -and ($foundServices -lt $requiredServiceCount)) {
    $services = Get-Service -DisplayName 'IVANTI*' | Where-Object { $_.Status -eq 'Running' }
    $foundServices = $services.Count

    Write-Log "$StrComputer : Found $foundServices out of $requiredServiceCount 'IVANTI' services running."

    Start-Sleep -Seconds 5
}

# Only remove the scheduled task if at least 1 IVANTI service is running
$taskName = "IvantiInstallAtStartup"
if ($foundServices -ge 1) {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Log "$StrComputer : Deleted scheduled task '$taskName' because at least one IVANTI service is running."
    } else {
        Write-Log "$StrComputer : Scheduled task '$taskName' not found."
    }
}
else {
    Write-Log "$StrComputer : Keeping scheduled task '$taskName' (no IVANTI service running)."
}
