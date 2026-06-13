#Requires -Version 5.1

param(
    [Parameter(Mandatory)]
    [string]$SqlServer,

    [Parameter(Mandatory)]
    [string]$Database,

    [Parameter(Mandatory)]
    [pscredential]$Credential,

    [int]$TimeoutSec = 15
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

    $packages = Invoke-EpmQuery -Query 'SELECT NAME, INSTALL, PACKAGE_FILES_HASH_IDN FROM dbo.PACKAGE'
    $filesHash = Invoke-EpmQuery -Query 'SELECT PACKAGE_FILES_HASH_IDN, FULL_PATH FROM dbo.PACKAGE_FILES_HASH'

    $filesById = @{}
    foreach ($file in $filesHash) {
        $filesById[[string]$file.PACKAGE_FILES_HASH_IDN] = [string]$file.FULL_PATH
    }

    $missing = foreach ($package in $packages) {
        if ([int]$package.INSTALL -ne 1) {
            continue
        }

        $hashId = [string]$package.PACKAGE_FILES_HASH_IDN
        if (-not $filesById.ContainsKey($hashId)) {
            continue
        }

        $path = $filesById[$hashId]
        $exists = $false

        if ($path -match '^https?://') {
            try {
                $response = Invoke-WebRequest -Uri $path -Method Head -UseBasicParsing -TimeoutSec $TimeoutSec
                $exists = ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400)
            }
            catch {
                $exists = $false
            }
        }
        elseif ($path -like '\\*') {
            $exists = Test-Path -LiteralPath $path
        }
        else {
            continue
        }

        if (-not $exists) {
            [pscustomobject]@{
                PackageName = [string]$package.NAME
                Path        = $path
            }
        }
    }

    $missing | Sort-Object PackageName, Path

    if ($missing) {
        exit 1
    }
}
finally {
    if ($connection.State -ne 'Closed') {
        $connection.Close()
    }
}
