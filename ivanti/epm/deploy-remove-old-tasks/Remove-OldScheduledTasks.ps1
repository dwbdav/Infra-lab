#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$SqlServer,

    [Parameter(Mandatory)]
    [string]$Database,

    [Parameter(Mandatory)]
    [pscredential]$SqlCredential,

    [Parameter(Mandatory)]
    [uri]$WebServiceUrl,

    [pscredential]$EpmCredential,

    [int]$RetentionDays = 30,

    [string[]]$ExcludeNamePattern = @('*PORTAL*', '*Download patch content*')
)

$ErrorActionPreference = 'Stop'

if (-not $EpmCredential) {
    $EpmCredential = Get-Credential -Message 'Ivanti EPM MBSDK credential'
}

$builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$builder['Data Source'] = $SqlServer
$builder['Initial Catalog'] = $Database
$builder['User ID'] = $SqlCredential.UserName
$builder['Password'] = $SqlCredential.GetNetworkCredential().Password
$builder['Integrated Security'] = $false
$builder['TrustServerCertificate'] = $true

$connection = [System.Data.SqlClient.SqlConnection]::new($builder.ConnectionString)

try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = 'SELECT LD_TASK_IDN, TASK_NAME, NEXT_START FROM dbo.LD_TASK'

    $reader = $command.ExecuteReader()
    $tasks = [System.Data.DataTable]::new()
    $tasks.Load($reader)
}
finally {
    if ($connection.State -ne 'Closed') {
        $connection.Close()
    }
}

$ldws = New-WebServiceProxy -Uri $WebServiceUrl.AbsoluteUri -Credential $EpmCredential
$now = Get-Date

foreach ($task in $tasks) {
    $taskName = [string]$task.TASK_NAME
    $taskId = [int]$task.LD_TASK_IDN
    $nextStartRaw = [string]$task.NEXT_START

    $excluded = $false
    foreach ($pattern in $ExcludeNamePattern) {
        if ($taskName -like $pattern) {
            $excluded = $true
            break
        }
    }
    if ($excluded) {
        Write-Verbose "Skipped excluded task: $taskName"
        continue
    }

    $nextStart = $null
    if (-not [DateTime]::TryParse($nextStartRaw, [ref]$nextStart)) {
        Write-Verbose "Skipped task without parseable NEXT_START: $taskName"
        continue
    }

    $ageDays = (New-TimeSpan -Start $nextStart -End $now).Days
    if ($ageDays -le $RetentionDays) {
        continue
    }

    $target = "$taskName [$taskId], age ${ageDays}d"
    if ($PSCmdlet.ShouldProcess($target, 'Delete Ivanti EPM scheduled task')) {
        $ldws.DeleteTask($taskId)
        Write-Host "Deleted: $target"
    }
}
