#Requires -Version 5.1

param(
    [Parameter(Mandatory)]
    [string]$SqlServer,

    [Parameter(Mandatory)]
    [string]$Database,

    [Parameter(Mandatory)]
    [pscredential]$Credential
)

$ErrorActionPreference = 'Stop'

$builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$builder['Data Source'] = $SqlServer
$builder['Initial Catalog'] = $Database
$builder['User ID'] = $Credential.UserName
$builder['Password'] = $Credential.GetNetworkCredential().Password
$builder['Integrated Security'] = $false
$builder['TrustServerCertificate'] = $true

$connection = [System.Data.SqlClient.SqlConnection]::new($builder.ConnectionString)

try {
    $connection.Open()

    function Invoke-EpmQuery {
        param([Parameter(Mandatory)][string]$Query)

        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        $reader = $command.ExecuteReader()
        $table = [System.Data.DataTable]::new()
        $table.Load($reader)
        return $table
    }

    $script:PreferredServers = Invoke-EpmQuery -Query 'SELECT PreferredServer_Idn, ServerName FROM dbo.PreferredServer'
    $script:IpLimits = Invoke-EpmQuery -Query 'SELECT PreferredServerIPLimit_Idn, PreferredServer_Idn, StartingIPAddress, EndingIPAddress FROM dbo.PreferredServerIPLimit'
}
finally {
    if ($connection.State -ne 'Closed') {
        $connection.Close()
    }
}

function ConvertTo-PaddedIPv4 {
    param([Parameter(Mandatory)][string]$IPAddress)

    $parts = $IPAddress.Split('.')
    if ($parts.Count -ne 4) {
        throw "Invalid IPv4 address: $IPAddress"
    }

    ($parts | ForEach-Object { '{0:000}' -f [int]$_ }) -join '.'
}

function Get-PreferredServerId {
    param([Parameter(Mandatory)][string]$Name)

    $server = $script:PreferredServers | Where-Object { $_.ServerName -eq $Name } | Select-Object -First 1
    if (-not $server) {
        throw "Preferred server not found: $Name"
    }

    return [int]$server.PreferredServer_Idn
}

function New-AddPreferredServerIpSql {
    param(
        [Parameter(Mandatory)][string]$PreferredServerName,
        [Parameter(Mandatory)][string]$StartAddress,
        [Parameter(Mandatory)][string]$EndAddress
    )

    $serverId = Get-PreferredServerId -Name $PreferredServerName
    $start = ConvertTo-PaddedIPv4 -IPAddress $StartAddress
    $end = ConvertTo-PaddedIPv4 -IPAddress $EndAddress

    $existing = $script:IpLimits | Where-Object {
        [int]$_.PreferredServer_Idn -eq $serverId -and
        [string]$_.StartingIPAddress -eq $start -and
        [string]$_.EndingIPAddress -eq $end
    }

    if (-not $existing) {
        "INSERT INTO dbo.PreferredServerIPLimit (PreferredServer_Idn, StartingIPAddress, EndingIPAddress) VALUES ($serverId, '$start', '$end');"
    }
}

function New-RemovePreferredServerIpSql {
    param(
        [Parameter(Mandatory)][string]$PreferredServerName,
        [Parameter(Mandatory)][string]$StartAddress,
        [Parameter(Mandatory)][string]$EndAddress
    )

    $serverId = Get-PreferredServerId -Name $PreferredServerName
    $start = ConvertTo-PaddedIPv4 -IPAddress $StartAddress
    $end = ConvertTo-PaddedIPv4 -IPAddress $EndAddress

    $script:IpLimits | Where-Object {
        [int]$_.PreferredServer_Idn -eq $serverId -and
        [string]$_.StartingIPAddress -eq $start -and
        [string]$_.EndingIPAddress -eq $end
    } | ForEach-Object {
        "DELETE FROM dbo.PreferredServerIPLimit WHERE PreferredServerIPLimit_Idn = $($_.PreferredServerIPLimit_Idn);"
    }
}

function New-RemoveAllPreferredServerIpSql {
    param([Parameter(Mandatory)][string]$PreferredServerName)

    $serverId = Get-PreferredServerId -Name $PreferredServerName

    $script:IpLimits | Where-Object {
        [int]$_.PreferredServer_Idn -eq $serverId
    } | ForEach-Object {
        "DELETE FROM dbo.PreferredServerIPLimit WHERE PreferredServerIPLimit_Idn = $($_.PreferredServerIPLimit_Idn);"
    }
}
