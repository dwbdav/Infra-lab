############################################### SQL ################################################################
$Exporthtml = "C:\Exploitation\WSUS\default.htm"
$configPath = "C:\Scripts\config.json"
############################################### SQL ################################################################


$config = Get-Content $configPath | ConvertFrom-Json
$ServerSQL = $config.SQL.Server
$database = $config.SQL.Database
$user = $config.SQL.Username
$password = $config.SQL.Password

# Convertir le mot de passe en SecureString
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($user, $securePassword)
$PassSQL = $creds.GetNetworkCredential().Password


Import-Module -Name PSwriteHTML
#. ([scriptblock]::Create((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DavidWuibaille/Repository/main/Function/DashboardEPM.ps1" -UseBasicParsing).Content))

# ----------------------------------------------------------------------------------------------------------------------
function Get-SqlData($connection, $query) {
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $result = $command.ExecuteReader()
    $table = New-Object System.Data.DataTable
    $table.Load($result)
    return $table
}

function Connect-SQLDatabase {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Server,

        [Parameter(Mandatory = $true)]
        [string]$Database,

        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$Password
    )

    try {
        # Construction de la chaîne de connexion
        $connectionString = "Server=$Server;uid=$User;pwd=$Password;Database=$Database;Integrated Security=False;"
        
        # Création de l'objet connexion SQL
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        
        # Ouverture de la connexion
        $connection.Open()
        Write-Host "------ Connected to Database: $Database on Server: $Server"
        
        # Retourne l'objet connexion
        return $connection
    } catch {
        # Gestion des erreurs
        Write-Host "------ Error connecting to Database: $Database on Server: $Server"
        Write-Host "------ Error details: $_"
        return $null
    }
}

function Get-ApplicationData {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$AppFilter
    )

    # Initialiser la collection pour stocker les données
    $ApplicationData = @()

    # Définir la requête SQL avec le filtre dynamique
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A1.SUITENAME, A1.VERSION
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN AppSoftwareSuites A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
        WHERE (A1.SUITENAME LIKE N'%$AppFilter%')
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $ApplicationData += [PSCustomObject]@{
            'APPLICATION'   = $element.SUITENAME
            'VERSION'     = $element.VERSION
            'DEVICENAME' = $element.DISPLAYNAME
        }
    }

    # Retourner la collection
    return $ApplicationData
}


function Get-BitlockerDetails {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    # Initialiser la collection pour stocker les données
    $BitlockerDetails = @()

    # Définir la requête SQL avec le filtre dynamique pour le système d'exploitation
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A2.SECUREBOOTENABLED, A2.UEFIENABLED, A3.CONVERSIONSTATUS,
                        A4.TPMENABLE, A4.TPMVERSION, A5.MODEL
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN Operating_System A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
        LEFT OUTER JOIN BIOS A2 (nolock) ON A0.Computer_Idn = A2.Computer_Idn
        LEFT OUTER JOIN BitLocker A3 (nolock) ON A0.Computer_Idn = A3.Computer_Idn
        LEFT OUTER JOIN TPMSystem A4 (nolock) ON A0.Computer_Idn = A4.Computer_Idn
        LEFT OUTER JOIN CompSystem A5 (nolock) ON A0.Computer_Idn = A5.Computer_Idn
        WHERE 
            A0.Computer_Idn NOT IN (
                SELECT Computer_Idn FROM Computer WHERE TYPE LIKE N'%Server%'
            )
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $BitlockerDetails += [PSCustomObject]@{
            'DEVICENAME'    = $element.DISPLAYNAME
            'BitLocker'     = if ([string]::IsNullOrEmpty($element.CONVERSIONSTATUS)) { "NoData" } else { $element.CONVERSIONSTATUS }
            'SECURE Boot'   = $element.SECUREBOOTENABLED
            'UEFI'          = $element.UEFIENABLED
            'TPM'           = $element.TPMENABLE
            'TPM Version'   = $element.TPMVERSION
            'Model'         = $element.MODEL
        }
    }

    # Retourner la collection d'objets
    return $BitlockerDetails
}


function Get-WindowsDetails {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    $WindowsDetails = @()
    $SkippedDevices = @()

    $query = @"
        SELECT DISTINCT 
            A0.DISPLAYNAME, 
            A1.OSTYPE, 
            A2.CURRENTBUILD, 
            A2.UBR
        FROM 
            Computer A0 (NOLOCK)
            LEFT OUTER JOIN Operating_System A1 (NOLOCK) ON A0.Computer_Idn = A1.Computer_Idn
            LEFT OUTER JOIN OSNT A2 (NOLOCK) ON A0.Computer_Idn = A2.Computer_Idn
        WHERE 
            A0.Computer_Idn NOT IN (
                SELECT Computer_Idn FROM Computer WHERE TYPE LIKE N'%Server%'
            )
        ORDER BY 
            A0.DISPLAYNAME
"@

    # Exécute la requête SQL
    $table = Get-SqlData -Connection $Connection -Query $query

    foreach ($element in $table) {
        $versionCode = Clean-WindowsVersion -OSType $element.OSTYPE -Build $element.CURRENTBUILD

        $ubrValue = if ([string]::IsNullOrWhiteSpace($element.UBR)) {
            $null
        } else {
            try {
                [int]$element.UBR
            } catch {
                $null
            }
        }

        if ($null -ne $ubrValue) {
            $WindowsDetails += [PSCustomObject]@{
                DEVICENAME = $element.DISPLAYNAME
                VERSION    = "$versionCode.$ubrValue"
            }
        } else {
            $SkippedDevices += $element.DISPLAYNAME
        }
    }

    if ($SkippedDevices.Count -gt 0) {
        Write-Warning "Les machines suivantes n'ont pas de valeur UBR valide et ont été ignorées :"
        $SkippedDevices | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
    }

    return $WindowsDetails | Sort-Object VERSION
}



function Close-SQLConnection {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    try {
        # Vérifier si la connexion est ouverte
        if ($Connection.State -eq [System.Data.ConnectionState]::Open) {
            $Connection.Close()
            Write-Host "------ Connection closed successfully."
        } else {
            Write-Host "------ Connection is already closed or not initialized."
        }
    } catch {
        # Gestion des erreurs
        Write-Host "------ Error closing the connection."
        Write-Host "------ Error details: $_"
    }
}

function Clean-WindowsVersion {
    param (
        [string]$OSType,
        [string]$Build
    )

    # Hashtable principale
    $buildMap = @{
        # Windows 11
        '22621' = 'w11_22H2'
        '22631' = 'w11_23H2'

        # Windows 10 - Standard
        '19041' = 'w10_2004'
        '19042' = 'w10_20H2'
        '19043' = 'w10_21H1'
        '19044' = 'w10_22H2'  # Peut être override via OSTYPE
        '19045' = 'w10_22H2'

        # Windows 10 - LTSC / LTSB
        '17763' = 'w10_LTSC2019'
        '14393' = 'w10_LTSB2016'

        # Windows 8.x / 7
        '9600'  = 'w81'
        '9200'  = 'w8'
        '7601'  = 'w7_sp1'

        # Windows Server
        '17763_srv' = 'ws2019'
        '20348'     = 'ws2022'
        '25398'     = 'ws2025'
    }

    # Gestion spéciale de certains builds ambigus
    if ($Build -eq '19044' -and $OSType -like '*LTSC 2021*') {
        return 'w10_LTSC2021'
    }

    if ($Build -eq '17763' -and $OSType -like '*Server*') {
        return $buildMap['17763_srv']
    }

    if ($Build -eq '14393' -and $OSType -like '*Server*') {
        return 'ws2016'
    }

    if ($buildMap.ContainsKey($Build)) {
        return $buildMap[$Build]
    }

    # Fallback dynamique
    if ($OSType -like '*Server*') {
        return "$Build"
    } else {
        return "$Build"
    }
}

function Clean-OSType {
    param (
        [string]$OSType
    )

    if (-not $OSType) { return "Unknown OS" }

    $os = $OSType

    # Nettoyage de base
    $os = $os -replace ',\s*64-bit', ''
    $os = $os -replace 'Microsoft\s+', ''
    $os = $os -replace '\s+Edition', ''

    # Patterns à détecter
    $patterns = @(
        @{ Pattern = 'Windows\s+10\s+Enterprise\s+2016\s+LTSB'; Replacement = 'Windows 10 LTSB 2016' },
        @{ Pattern = 'Windows\s+10\s+Enterprise\s+LTSC\s+2019'; Replacement = 'Windows 10 LTSC 2019' },
        @{ Pattern = 'Windows\s+10\s+Enterprise\s+LTSC\s+2021'; Replacement = 'Windows 10 LTSC 2021' },
        @{ Pattern = 'Windows\s+10\s+Enterprise';              Replacement = 'Windows 10 Enterprise' },
        @{ Pattern = 'Windows\s+11\s+Enterprise';              Replacement = 'Windows 11 Enterprise' },
        @{ Pattern = 'Windows\s+10\s+IoT\s+Enterprise';         Replacement = 'Windows 10 IoT Enterprise' },
        @{ Pattern = 'Windows\s+Server\s+(\d+)\s+Datacenter';   Replacement = 'Windows Server $1 Datacenter' },
        @{ Pattern = 'Windows\s+Server\s+(\d+)\s+Standard';     Replacement = 'Windows Server $1 Standard' }
    )

    foreach ($p in $patterns) {
        if ($os -match $p.Pattern) {
            return ($os -replace $p.Pattern, $p.Replacement)
        }
    }

    # Fallback : retourne nom nettoyé
    return $os
}

function Get-WorkstationModels {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    $workstationModels = New-Object System.Collections.Generic.List[object]

    $query = @"
SELECT DISTINCT 
    A0.DISPLAYNAME, 
    A1.MODEL, 
    A2.OSTYPE  
FROM 
    Computer A0 WITH (NOLOCK)
    LEFT JOIN CompSystem A1 WITH (NOLOCK) ON A0.Computer_Idn = A1.Computer_Idn
    LEFT JOIN Operating_System A2 WITH (NOLOCK) ON A0.Computer_Idn = A2.Computer_Idn
ORDER BY 
    A0.DISPLAYNAME
"@

    Write-Verbose "Executing SQL query to retrieve workstation models."

    $table = Get-SqlData -Connection $Connection -Query $query

    foreach ($row in $table) {
        $modelValue = if ([string]::IsNullOrWhiteSpace($row.MODEL) -or $row.MODEL -eq 'Default string') {
            'No Data'
        } else {
            $row.MODEL
        }

        $cleanOS = Clean-OSType -OSType $row.OSTYPE

        $workstationModels.Add([PSCustomObject]@{
            DEVICENAME = $row.DISPLAYNAME
            MODEL      = $modelValue
            OS         = $cleanOS
        })
    }

    return $workstationModels
}

function Get-WorkstationManufacturers {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    # Initialiser la collection pour stocker les données
    $ManufacturerData = @()

    # Définir la requête SQL
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A1.MANUFACTURER
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN CompSystem A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
        WHERE (A0.Computer_Idn NOT IN (
            SELECT Computer_Idn 
            FROM Computer 
            WHERE TYPE LIKE N'%Server%'
        ))
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $ManufacturerData += [PSCustomObject]@{
            'DEVICENAME'    = $element.DISPLAYNAME
            'MANUFACTURER'  = if ([string]::IsNullOrEmpty($element.MANUFACTURER)) { "NoData" } else { $element.MANUFACTURER }
        }
    }

    # Retourner la collection d'objets
    return $ManufacturerData
}


function Get-EnvironmentVariables {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection,

        [Parameter(Mandatory = $true)]
        [string]$VariableName
    )

    # Initialiser la collection pour stocker les données
    $EnvironmentVariables = @()

    # Définir la requête SQL avec le filtre pour le nom de la variable
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A1.VALUESTRING
        FROM Computer A0 (nolock)
        LEFT OUTER JOIN EnvironSettings A1 (nolock) ON A0.Computer_Idn = A1.Computer_Idn
        WHERE (A0.Computer_Idn NOT IN (
            SELECT Computer_Idn 
            FROM Computer 
            WHERE TYPE LIKE N'%Server%'
        ))
        AND A1.NAME = N'$VariableName'
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $EnvironmentVariables += [PSCustomObject]@{
            'DEVICENAME' = $element.DISPLAYNAME
            'VALUE'      = $element.VALUESTRING
        }
    }

    # Retourner la collection d'objets
    return $EnvironmentVariables
}

function Get-HardwareScanDay {
    param (
        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    # Initialiser la collection pour stocker les données
    $HardwareScanData = @()

    # Définir la requête SQL
    $query = @"
        SELECT DISTINCT A0.DISPLAYNAME, A0.HWLASTSCANDATE
        FROM Computer A0 (nolock)
        WHERE (A0.Computer_Idn NOT IN (
            SELECT Computer_Idn 
            FROM Computer 
            WHERE TYPE LIKE N'%Server%'
        ))
        ORDER BY A0.DISPLAYNAME
"@

    # Exécuter la requête et charger les résultats
    $table = Get-SqlData -Connection $Connection -Query $query

    # Parcourir les résultats et remplir la collection
    foreach ($element in $table) {
        $scanDate = $element.HWLASTSCANDATE
        $daysDifference = (Get-Date) - [datetime]$scanDate

        # Classifier la date selon les intervalles
        $category = switch ($true) {
            ($daysDifference.TotalDays -le 7)  { "<7 jours" }
            ($daysDifference.TotalDays -le 14) { "<14 jours" }
            ($daysDifference.TotalDays -le 30) { "<30 jours" }
            ($daysDifference.TotalDays -le 90) { "<90 jours" }
            default                            { ">90 jours" }
        }

        $HardwareScanData += [PSCustomObject]@{
            'DEVICENAME'      = $element.DISPLAYNAME
            'SCAN_CATEGORY'   = $category
        }
    }

    # Retourner la collection d'objets
    return $HardwareScanData
}


#$Connection            = Connect-SQLDatabase                     -Server $ServerSQL -Database $database -User $user -Password $PassSQL
#$Application1          = Get-ApplicationData                     -Connection $Connection -AppFilter $ApplicationFilter1
#$Application2          = Get-ApplicationData                     -Connection $Connection -AppFilter $ApplicationFilter2
#$BitlockerDetails      = Get-BitlockerDetails                    -Connection $Connection
#$WindowsDetails        = Get-WindowsDetails                      -Connection $Connection
#$WorkstationModels     = Get-WorkstationModels                   -Connection $Connection
#$WorkstationMakes      = Get-WorkstationManufacturers            -Connection $Connection
#$Variable1             = Get-EnvironmentVariables                -Connection $Connection -VariableName $VariableFilter1
#$HardwareScanDay       = Get-HardwareScanDay                     -Connection $Connection
#$WindowsgroupesVersion = $WindowsDetails    | Group-Object -Property VERSION
#$BitlockerStatus       = $BitlockerDetails  | Group-Object -Property Bitlocker
#$Modelscount           = $WorkstationModels | Group-Object -Property MODEL
#$Makesount             = $WorkstationMakes  | Group-Object -Property MANUFACTURER
#$ScanDaycount          = HardwareScanDay    | Group-Object -Property SCAN_CATEGORY
#Close-SQLConnection -Connection $Connection



# ----------------------------------------------------------------------------------------------------------------------

$Connection            = Connect-SQLDatabase                     -Server $ServerSQL -Database $database -User $user -Password $PassSQL
#$Application1          = Get-ApplicationData                     -Connection $Connection -AppFilter $ApplicationFilter1
#$Application2          = Get-ApplicationData                     -Connection $Connection -AppFilter $ApplicationFilter2
#$BitlockerDetails      = Get-BitlockerDetails                    -Connection $Connection
$WindowsDetails        = Get-WindowsDetails                      -Connection $Connection
$WorkstationModels     = Get-WorkstationModels                   -Connection $Connection
#$WorkstationMakes      = Get-WorkstationManufacturers            -Connection $Connection
#$Variable1             = Get-EnvironmentVariables                -Connection $Connection -VariableName $VariableFilter1
#$HardwareScanDay       = Get-HardwareScanDay                     -Connection $Connection
$WindowsgroupesVersion = $WindowsDetails    | Group-Object -Property VERSION
#$BitlockerStatus       = $BitlockerDetails  | Group-Object -Property Bitlocker
$Modelscount           = $WorkstationModels | Group-Object -Property MODEL
$Makesount             = $WorkstationMakes  | Group-Object -Property MANUFACTURER
#$ScanDaycount          = HardwareScanDay    | Group-Object -Property SCAN_CATEGORY
Close-SQLConnection -Connection $Connection

$WindowsMajorMap = $WindowsDetails | ForEach-Object {
    $major = ($_.VERSION -split '\.')[0]
    [PSCustomObject]@{
        MAJORVERSION = $major
        DEVICENAME   = $_.DEVICENAME
    }
}



# Sauvegarde quotidienne des versions Windows
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$historyFile = Join-Path -Path $scriptPath -ChildPath "windows_versions_history.csv"
$today = (Get-Date -Format "yyyy-MM-dd")

$todayData = $WindowsgroupesVersion | ForEach-Object {
    [PSCustomObject]@{
        Date    = $today
        Version = $_.Name
        Count   = $_.Count
    }
}

$yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")



$raw = Import-Csv -Path $historyFile

$cleaned = foreach ($entry in $raw) {
    $date    = $entry.Date
    $version = $entry.Version
    $count   = [int]$entry.Count

    $parts = $version -split '\.'
    $build = $parts[0]
    $ubr   = $parts[1]

    if ($ubr -match '^\d+$') {
        $cleanCode = Clean-WindowsVersion -OSType '' -Build $build
        [PSCustomObject]@{
            Date    = $date
            Version = "$cleanCode.$ubr"
            Count   = $count
        }
    }
}

# Réécriture propre du CSV (overwrite)
$cleaned | Export-Csv -Path $historyFile -NoTypeInformation -Encoding UTF8
# Génération des courbes temporelles
$rawHistory = Import-Csv -Path $historyFile

# Nettoyage et enrichissement des lignes
$historyParsed = foreach ($entry in $rawHistory) {
    $date   = $entry.Date
    $rawVer = $entry.Version
    $count  = [int]$entry.Count

    # Découper Version brute : "17763.7009" => Build + UBR
	$parts = $rawVer -split '\.'
	$build = $parts[0]
	$ubr   = if ($parts[1] -match '^\d+$') { [int]$parts[1] } else { $null }


    # Appeler Clean-WindowsVersion pour retrouver le VersionCode
    $versionCode = Clean-WindowsVersion -OSType '' -Build $build

    [PSCustomObject]@{
        Date        = $date
        VersionCode = $versionCode
        UBR         = $ubr
        Count       = $count
    }
}



# Reconstruire version finale sans tag .old
$history = foreach ($row in $historyParsed) {
    [PSCustomObject]@{
        Date    = $row.Date
        Version = "$($row.VersionCode).$($row.UBR)"
        Count   = $row.Count
    }
}

# Assurer que Count est bien un entier (au cas où CSV l'ait converti en string)
$history | ForEach-Object { $_.Count = [int]$_.Count }

$versions = $history.Version | Sort-Object -Unique
$dates = $history.Date | Sort-Object -Unique

# Courbe pour chaque version complète
$lines = foreach ($version in $versions) {
    $valeurs = foreach ($date in $dates) {
        $sum = ($history | Where-Object { $_.Date -eq $date -and $_.Version -eq $version } | Measure-Object -Property Count -Sum).Sum
        if (-not $sum) { $sum = 0 }
        $sum
    }
    [PSCustomObject]@{
        Version = $version
        Values  = $valeurs
    }
}

# Ajouter colonne MajorVersion à partir de Version
$historyGrouped = $history | ForEach-Object {
    $_ | Add-Member -NotePropertyName "MajorVersion" -NotePropertyValue ($_.Version -split '\.')[0] -Force
    $_
}

# Liste des versions majeures uniques
$majorVersions = $historyGrouped.MajorVersion | Sort-Object -Unique

# Courbes pour les versions majeures
$linesMajor = foreach ($version in $majorVersions) {
    $valeurs = foreach ($date in $dates) {
        $sum = ($historyGrouped | Where-Object {
            $_.Date -eq $date -and $_.MajorVersion -eq $version
        } | Measure-Object -Property Count -Sum).Sum

        if (-not $sum) { $sum = 0 }
        $sum
    }

    $displayName = $version

    [PSCustomObject]@{
        Version = $displayName
        Values  = $valeurs
    }
}



# Rapport HTML
New-HTML -TitleText 'Dashboard' {

    # Onglet Windows - Donut chart actuel
    New-HTMLTab -Name 'Windows' {
        New-HTMLSection -HeaderText 'Windows Versions Over Time' {
            New-HTMLPanel {
                New-HTMLChart -Title "Windows Versions (Daily Evolution)" -TitleAlignment center {
                    New-ChartAxisX -Names $dates
                    foreach ($line in $lines) {
                        New-ChartLine -Name $line.Version -Value $line.Values
                    }
                }
            }
        }
        New-HTMLSection -HeaderText 'Windows Version' {
            New-HTMLPanel {
                New-HTMLChart -Title "Version" {
                    New-ChartToolbar -Download
                    New-ChartEvent -DataTableID 'WindowsOS' -ColumnID 1
                    foreach ($groupe in $WindowsgroupesVersion) {
                        New-ChartDonut -Name $($groupe.Name) -Value $($groupe.Count)
                    }
                }
            }
			New-HTMLPanel {
                New-HTMLTable -DataTable $WindowsDetails -DataTableID 'WindowsOS' -HideFooter
            }
        }



    }

    # Onglet Windows major
    New-HTMLTab -Name 'Windows major' {

        New-HTMLSection -HeaderText 'Windows Versions Over Time (Grouped by Major Version)' {
            New-HTMLPanel {
                New-HTMLChart -Title "Windows Major Versions (Daily Evolution)" -TitleAlignment center {
                    New-ChartAxisX -Names $dates
                    foreach ($line in $linesMajor) {
                        New-ChartLine -Name $line.Version -Value $line.Values
                    }
                }
            }
		}
		New-HTMLSection -HeaderText 'Windows Versions' {
            New-HTMLPanel {
                New-HTMLChart -Title "Windows Major" {
                    New-ChartToolbar -Download
					New-ChartEvent -DataTableID 'WindowsV' -ColumnID 0
                    foreach ($line in $linesMajor) {
                        $total = ($line.Values | Measure-Object -Sum).Sum
                        New-ChartDonut -Name $($line.Version) -Value $total
                    }
                }
            }
			New-HTMLPanel {
                New-HTMLTable -DataTable $WindowsMajorMap -DataTableID 'WindowsV' -HideFooter
            }
        }
    }

    # Onglet Hardware
    New-HTMLTab -Name 'Model' {
        New-HTMLSection -HeaderText 'Hardware' {
            New-HTMLPanel {
                New-HTMLChart -Title "Version" {
                    New-ChartToolbar -Download
                    New-ChartEvent -DataTableID 'Modelcount' -ColumnID 1
                    foreach ($groupe in $Modelscount) {
                        New-ChartDonut -Name $($groupe.Name) -Value $($groupe.Count)
                    }
                }
				New-HTMLPanel {
					New-HTMLTable -DataTable $WorkstationModels -DataTableID 'Modelcount' -HideFooter
				}
            }
        }

    }

    # Pied de page
    New-HTMLFooter {
        New-HTMLText -Text "Date of this report (GMT time): $(Get-Date)" -Color Blue -Alignment Center 
    }

} -FilePath $Exporthtml -Online
