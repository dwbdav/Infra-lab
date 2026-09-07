#requires -Version 5.1

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# -------------------------------------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------------------------------------
$ScriptDirectory = $PSScriptRoot
$configPath      = Join-Path -Path $ScriptDirectory -ChildPath 'config.json'
$ExportHtml      = Join-Path -Path $ScriptDirectory -ChildPath 'default.htm'

# -------------------------------------------------------------------------------------------------
# Prerequisites
# -------------------------------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Configuration file not found: $configPath"
}

if (-not (Get-Module -ListAvailable -Name PSWriteHTML)) {
    throw 'PSWriteHTML is not installed. Run: Install-Module PSWriteHTML -Scope CurrentUser -Force'
}

Import-Module PSWriteHTML -ErrorAction Stop

# -------------------------------------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------------------------------------
try {
    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
}
catch {
    throw "Unable to read config.json. Check that the JSON syntax is valid. Error: $($_.Exception.Message)"
}

$ServerSQL = [string]$config.SQL.Server
$Database  = [string]$config.SQL.Database
$User      = [string]$config.SQL.Username
$Password  = [string]$config.SQL.Password

if ([string]::IsNullOrWhiteSpace($ServerSQL) -or
    [string]::IsNullOrWhiteSpace($Database)  -or
    [string]::IsNullOrWhiteSpace($User)) {
    throw 'SQL.Server, SQL.Database and SQL.Username must be defined in config.json.'
}

# -------------------------------------------------------------------------------------------------
# SQL functions
# -------------------------------------------------------------------------------------------------
function Get-SqlData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]$Connection,

        [Parameter(Mandatory)]
        [string]$Query
    )

    $command = $Connection.CreateCommand()
    $command.CommandText = $Query
    $command.CommandTimeout = 120

    $reader = $command.ExecuteReader()

    try {
        $table = New-Object System.Data.DataTable
        $table.Load($reader)
        return $table
    }
    finally {
        if (-not $reader.IsClosed) {
            $reader.Close()
        }
        $command.Dispose()
    }
}

function Connect-SQLDatabase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter(Mandatory)]
        [string]$Database,

        [Parameter(Mandatory)]
        [string]$User,

        [Parameter(Mandatory)]
        [string]$Password
    )

    $connectionString = "Server=$Server;Database=$Database;User ID=$User;Password=$Password;Integrated Security=False;Application Name=IvantiEPMDashboard;"

    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString

    try {
        $connection.Open()
        Write-Host "Connected to database '$Database' on '$Server'." -ForegroundColor Green
        return $connection
    }
    catch {
        $connection.Dispose()
        throw "Unable to connect to database '$Database' on '$Server'. Error: $($_.Exception.Message)"
    }
}

function Close-SQLConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    try {
        if ($Connection.State -eq [System.Data.ConnectionState]::Open) {
            $Connection.Close()
        }
    }
    finally {
        $Connection.Dispose()
    }
}

# -------------------------------------------------------------------------------------------------
# Windows classification
# Standard and Datacenter editions are intentionally grouped by Windows Server release.
# -------------------------------------------------------------------------------------------------
function Get-WindowsReleaseInfo {
    [CmdletBinding()]
    param (
        [string]$OSType,
        [string]$ComputerType,
        [string]$Build
    )

    $isServer = ($OSType -like '*Server*') -or ($ComputerType -like '*Server*')

    if ($isServer) {
        switch ($Build) {
            '26100' {
                return [PSCustomObject]@{ Family = 'Windows Server'; Release = 'Windows Server 2025'; Order = 2025 }
            }
            '25398' {
                return [PSCustomObject]@{ Family = 'Windows Server'; Release = 'Windows Server 2025'; Order = 2025 }
            }
            '20348' {
                return [PSCustomObject]@{ Family = 'Windows Server'; Release = 'Windows Server 2022'; Order = 2022 }
            }
            '17763' {
                return [PSCustomObject]@{ Family = 'Windows Server'; Release = 'Windows Server 2019'; Order = 2019 }
            }
            '14393' {
                return [PSCustomObject]@{ Family = 'Windows Server'; Release = 'Windows Server 2016'; Order = 2016 }
            }
            default {
                return [PSCustomObject]@{
                    Family  = 'Unclassified'
                    Release = if ($OSType) { $OSType } else { "Windows Server build $Build" }
                    Order   = 0
                }
            }
        }
    }

    switch ($Build) {
        # Windows 11
        '26200' {
            return [PSCustomObject]@{ Family = 'Windows 11'; Release = 'Windows 11 25H2'; Order = 2500 }
        }
        '26100' {
            return [PSCustomObject]@{ Family = 'Windows 11'; Release = 'Windows 11 24H2'; Order = 2400 }
        }
        '22631' {
            return [PSCustomObject]@{ Family = 'Windows 11'; Release = 'Windows 11 23H2'; Order = 2300 }
        }
        '22621' {
            return [PSCustomObject]@{ Family = 'Windows 11'; Release = 'Windows 11 22H2'; Order = 2200 }
        }
        '22000' {
            return [PSCustomObject]@{ Family = 'Windows 11'; Release = 'Windows 11 21H2'; Order = 2100 }
        }

        # Windows 10
        '19045' {
            return [PSCustomObject]@{ Family = 'Windows 10'; Release = 'Windows 10 22H2'; Order = 2200 }
        }
        '19044' {
            if ($OSType -match '(?i)IoT.*2021|2021.*IoT') {
                return [PSCustomObject]@{ Family = 'Windows 10'; Release = 'Windows 10 IoT 2021'; Order = 2150 }
            }

            if ($OSType -match '(?i)LTSC.*2021|2021.*LTSC') {
                return [PSCustomObject]@{ Family = 'Windows 10'; Release = 'Windows 10 LTSC 2021'; Order = 2140 }
            }

            return [PSCustomObject]@{ Family = 'Windows 10'; Release = 'Windows 10 21H2'; Order = 2100 }
        }
        '19043' {
            return [PSCustomObject]@{ Family = 'Windows 10'; Release = 'Windows 10 21H1'; Order = 2050 }
        }
        '19042' {
            return [PSCustomObject]@{ Family = 'Windows 10'; Release = 'Windows 10 20H2'; Order = 2000 }
        }
        '19041' {
            return [PSCustomObject]@{ Family = 'Windows 10'; Release = 'Windows 10 2004'; Order = 1900 }
        }
        '17763' {
            return [PSCustomObject]@{ Family = 'Windows 10'; Release = 'Windows 10 LTSC 2019'; Order = 1800 }
        }
        '14393' {
            return [PSCustomObject]@{ Family = 'Windows 10'; Release = 'Windows 10 LTSB 2016'; Order = 1600 }
        }
        '10240' {
            return [PSCustomObject]@{ Family = 'Windows 10'; Release = 'Windows 10 LTSB 2015'; Order = 1500 }
        }

        default {
            return [PSCustomObject]@{
                Family  = 'Unclassified'
                Release = if ($OSType) { $OSType } else { "Windows build $Build" }
                Order   = 0
            }
        }
    }
}

function Get-WindowsInventory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    $query = @"
SELECT DISTINCT
    A0.DISPLAYNAME,
    A0.TYPE AS COMPUTERTYPE,
    A1.OSTYPE,
    A2.CURRENTBUILD,
    A2.UBR
FROM Computer A0 WITH (NOLOCK)
LEFT JOIN Operating_System A1 WITH (NOLOCK)
    ON A0.Computer_Idn = A1.Computer_Idn
LEFT JOIN OSNT A2 WITH (NOLOCK)
    ON A0.Computer_Idn = A2.Computer_Idn
WHERE
    A1.OSTYPE LIKE N'%Windows%'
ORDER BY
    A0.DISPLAYNAME
"@

    $table = Get-SqlData -Connection $Connection -Query $query
    $inventory = New-Object System.Collections.Generic.List[object]

    foreach ($row in $table) {
        $build = if ($null -eq $row.CURRENTBUILD -or $row.CURRENTBUILD -is [DBNull]) {
            ''
        }
        else {
            [string]$row.CURRENTBUILD
        }

        $osType = if ($null -eq $row.OSTYPE -or $row.OSTYPE -is [DBNull]) {
            ''
        }
        else {
            [string]$row.OSTYPE
        }

        $computerType = if ($null -eq $row.COMPUTERTYPE -or $row.COMPUTERTYPE -is [DBNull]) {
            ''
        }
        else {
            [string]$row.COMPUTERTYPE
        }

        $releaseInfo = Get-WindowsReleaseInfo -OSType $osType -ComputerType $computerType -Build $build

        $ubr = if ($null -eq $row.UBR -or $row.UBR -is [DBNull] -or [string]::IsNullOrWhiteSpace([string]$row.UBR)) {
            'No UBR'
        }
        else {
            [string]$row.UBR
        }

        $inventory.Add([PSCustomObject]@{
            DEVICENAME   = [string]$row.DISPLAYNAME
            FAMILY       = $releaseInfo.Family
            RELEASE      = $releaseInfo.Release
            RELEASEORDER = [int]$releaseInfo.Order
            BUILD        = $build
            UBR          = $ubr
            OSTYPE       = $osType
        })
    }

    return $inventory
}

# -------------------------------------------------------------------------------------------------
# Dashboard helper functions
# -------------------------------------------------------------------------------------------------
function Get-ReleaseGroups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]]$Inventory,

        [Parameter(Mandatory)]
        [string]$Family
    )

    $familyData = @($Inventory | Where-Object { $_.FAMILY -eq $Family })

    if ($familyData.Count -eq 0) {
        return @()
    }

    return @(
        $familyData |
            Group-Object -Property RELEASE |
            ForEach-Object {
                $first = $_.Group | Select-Object -First 1

                [PSCustomObject]@{
                    Release = $_.Name
                    Order   = [int]$first.RELEASEORDER
                    Count   = $_.Count
                    Devices = @($_.Group)
                }
            } |
            Sort-Object -Property Order -Descending
    )
}

function Get-UBRGroups {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]]$Devices
    )

    $groups = @(
        $Devices |
            Group-Object -Property UBR |
            ForEach-Object {
                $numericValue = -1
                $isNumeric = [int]::TryParse([string]$_.Name, [ref]$numericValue)

                [PSCustomObject]@{
                    UBR        = [string]$_.Name
                    Count      = $_.Count
                    IsNumeric  = $isNumeric
                    NumericUBR = if ($isNumeric) { $numericValue } else { -1 }
                }
            }
    )

    return @(
        $groups |
            Sort-Object `
                @{ Expression = 'IsNumeric'; Descending = $true }, `
                @{ Expression = 'NumericUBR'; Descending = $true }, `
                @{ Expression = 'UBR'; Descending = $true }
    )
}

function Add-ReleaseDashboardRow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Release,

        [Parameter(Mandatory)]
        [object[]]$Devices
    )

    $deviceCount = $Devices.Count
    $ubrGroups   = @(Get-UBRGroups -Devices $Devices)

    # One OS release per line.
    # The left panel contains the total and the right panel uses most of the width for the UBR chart.
    New-HTMLSection -Invisible -Width '100%' -Wrap 'nowrap' -Direction 'row' {

        New-HTMLPanel -Width '24%' -Height 360 -AlignContentText center -Margin '2px' {
            New-HTMLText -Text $Release -FontSize 14 -Alignment Left -FontWeight 500
            New-HTMLText -Text ([string]$deviceCount) -FontSize 58 -Alignment Center -FontWeight 400
            New-HTMLText -Text $Release -FontSize 38 -Alignment Center -FontWeight 400
        }

        New-HTMLPanel -Width '74%' -Height 360 -Margin '2px' {
            New-HTMLChart -Title 'RELEASE ID' -TitleAlignment Left -Height 325 {

                New-ChartToolbar -Download

                # Hide the ApexCharts series legend.
                # The UBR values are displayed directly as the X-axis categories.
                New-ChartLegend -HideLegend

                New-ChartBarOptions `
                    -Vertical `
                    -Distributed `
                    -DataLabelsEnabled $true `
                    -DataLabelsOffsetX 0 `
                    -DataLabelsFontSize '11px'

                # IMPORTANT:
                # One New-ChartBar per UBR is required by PSWriteHTML.
                # Passing the whole value array to a single New-ChartBar produces "series-1",
                # "series-2", etc. instead of UBR labels.
                foreach ($ubrGroup in $ubrGroups) {
                    New-ChartBar -Name ([string]$ubrGroup.UBR) -Value ([int]$ubrGroup.Count)
                }
            }
        }
    }
}

function Add-WindowsFamilySectionCompact {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Header,

        [Parameter(Mandatory)]
        [object[]]$ReleaseGroups
    )

    if ($ReleaseGroups.Count -eq 0) {
        return
    }

    # Compact layout: several OS releases can be displayed on the same line.
    # This reproduces the previous dashboard layout.
    New-HTMLSection -HeaderText $Header {
        foreach ($releaseGroup in $ReleaseGroups) {
            Add-ReleaseDashboardRow -Release $releaseGroup.Release -Devices $releaseGroup.Devices
        }
    }
}

function Add-WindowsFamilySectionFullWidth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Header,

        [Parameter(Mandatory)]
        [object[]]$ReleaseGroups
    )

    if ($ReleaseGroups.Count -eq 0) {
        return
    }

    # Full-width layout: one OS release per line.
    New-HTMLSection `
        -HeaderText $Header `
        -Width '100%' `
        -Direction 'column' `
        -Wrap 'nowrap' {

        foreach ($releaseGroup in $ReleaseGroups) {
            Add-ReleaseDashboardRow -Release $releaseGroup.Release -Devices $releaseGroup.Devices
        }
    }
}

# -------------------------------------------------------------------------------------------------
# Collect current inventory
# -------------------------------------------------------------------------------------------------
$Connection = $null

try {
    $Connection = Connect-SQLDatabase -Server $ServerSQL -Database $Database -User $User -Password $Password
    $WindowsInventory = @(Get-WindowsInventory -Connection $Connection)
}
finally {
    if ($null -ne $Connection) {
        Close-SQLConnection -Connection $Connection
    }
}

$Windows11Groups     = @(Get-ReleaseGroups -Inventory $WindowsInventory -Family 'Windows 11')
$Windows10Groups     = @(Get-ReleaseGroups -Inventory $WindowsInventory -Family 'Windows 10')
$WindowsServerGroups = @(Get-ReleaseGroups -Inventory $WindowsInventory -Family 'Windows Server')
$UnclassifiedWindows = @($WindowsInventory | Where-Object { $_.FAMILY -eq 'Unclassified' })

Write-Host "Windows 11 devices : $((@($WindowsInventory | Where-Object FAMILY -eq 'Windows 11')).Count)"
Write-Host "Windows 10 devices : $((@($WindowsInventory | Where-Object FAMILY -eq 'Windows 10')).Count)"
Write-Host "Windows Server devices : $((@($WindowsInventory | Where-Object FAMILY -eq 'Windows Server')).Count)"

if ($UnclassifiedWindows.Count -gt 0) {
    Write-Warning "$($UnclassifiedWindows.Count) Windows device(s) could not be mapped to a known release. They will be displayed in the report."
}

# -------------------------------------------------------------------------------------------------
# Generate current-state HTML dashboard
# -------------------------------------------------------------------------------------------------
New-HTML -TitleText 'Ivanti EPM - Windows Patching Dashboard' {

    New-HTMLTab -Name 'Windows Compact' {

        Add-WindowsFamilySectionCompact -Header 'WINDOWS 11 PATCHING' -ReleaseGroups $Windows11Groups
        Add-WindowsFamilySectionCompact -Header 'WINDOWS 10 PATCHING' -ReleaseGroups $Windows10Groups
        Add-WindowsFamilySectionCompact -Header 'WINDOWS SERVER PATCHING' -ReleaseGroups $WindowsServerGroups

        if ($UnclassifiedWindows.Count -gt 0) {
            New-HTMLSection -HeaderText 'UNCLASSIFIED WINDOWS' {
                New-HTMLTable -DataTable (
                    $UnclassifiedWindows |
                        Select-Object DEVICENAME, OSTYPE, BUILD, UBR
                ) -HideFooter -SearchPane
            }
        }
    }

    New-HTMLTab -Name 'Windows Full Width' {

        Add-WindowsFamilySectionFullWidth -Header 'WINDOWS 11 PATCHING' -ReleaseGroups $Windows11Groups
        Add-WindowsFamilySectionFullWidth -Header 'WINDOWS 10 PATCHING' -ReleaseGroups $Windows10Groups
        Add-WindowsFamilySectionFullWidth -Header 'WINDOWS SERVER PATCHING' -ReleaseGroups $WindowsServerGroups

        if ($UnclassifiedWindows.Count -gt 0) {
            New-HTMLSection -HeaderText 'UNCLASSIFIED WINDOWS' {
                New-HTMLTable -DataTable (
                    $UnclassifiedWindows |
                        Select-Object DEVICENAME, OSTYPE, BUILD, UBR
                ) -HideFooter -SearchPane
            }
        }
    }

    New-HTMLFooter {
        New-HTMLText -Text "Report generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color Blue -Alignment Center
    }

} -FilePath $ExportHtml -Online

Write-Host "Dashboard generated: $ExportHtml" -ForegroundColor Green
