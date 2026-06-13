#requires -version 5.1
<#
  MSU Prereq + Install + WS logging + STRICT selection by FULL BUILD (major.UBR)
  - Mapping is downloaded from https://nas.wuibaille.fr/WS/patchs/msu.json
  - Supports multiple packages per build (e.g., SSU then LCU)
  - JSON needs only: { "<build>": { "packages": [ { "url": "...", "type": "LCU", "order": 20 }, ... ] } }
  - No defaults: if build key missing -> exit 111
  - If JSON cannot be downloaded and no cache -> exit 112
  - If cached JSON invalid -> exit 113
#>

# -------- Settings --------
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

$ComputerName   = $env:COMPUTERNAME
$LogPath        = "C:\Windows\Temp\MSU_Install.log"
$ApiUrl         = "https://nas.wuibaille.fr/WS/message.php"
$SendLogsToWS   = $true

# Remote JSON map + local cache
$MsuMapUrl      = "https://nas.wuibaille.fr/WS/patchs/msu.json"
$MsuMapCache    = "C:\Windows\Temp\msu.json"

# Optional: force a build key like '17763.7786'
$OverrideBuildFull = $null

# -------- Helpers --------
function Write-Log {
    param([Parameter(Mandatory)][string]$Message)
    $timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fullMessage = "[$ComputerName] $Message"
    Add-Content -Path $LogPath -Value "$timestamp $fullMessage" -Encoding UTF8
    Write-Host  $fullMessage
    if ($SendLogsToWS) {
        try {
            $body = @{ message = $fullMessage } | ConvertTo-Json -Depth 2
            $null = Invoke-RestMethod -Uri $ApiUrl -Method POST -Body $body -ContentType "application/json" -TimeoutSec 10 -ErrorAction Stop
        } catch {
            Write-Warning ("[$ComputerName] Webservice log failed: {0}" -f $_.Exception.Message)
        }
    }
}

function Get-BuildFull {
    # Returns PSCustomObject with BuildMajor, UBR, BuildFull="major.UBR"
    $cvPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $cv     = Get-ItemProperty -LiteralPath $cvPath

    $buildStr   = [string]$cv.CurrentBuild
    if ([string]::IsNullOrWhiteSpace($buildStr)) { $buildStr = [string]$cv.CurrentBuildNumber }
    $buildMajor = [int]$buildStr

    $ubr = 0; try { $ubr = [int]$cv.UBR } catch {}

    [PSCustomObject]@{
        BuildMajor = $buildMajor
        UBR        = $ubr
        BuildFull  = ('{0}.{1}' -f $buildMajor, $ubr)
    }
}

function Get-MSUMapFromJson {
    # Downloads JSON (and caches it). On failure, tries cache; else exits.
    Write-Log ("Fetching MSU map: {0}" -f $MsuMapUrl)
    try {
        $json = Invoke-RestMethod -Uri $MsuMapUrl -Method GET -TimeoutSec 15 -ErrorAction Stop
        try { ($json | ConvertTo-Json -Depth 10) | Out-File -FilePath $MsuMapCache -Encoding UTF8 -Force } catch {}
        return $json
    } catch {
        Write-Log ("Online map fetch failed: {0}" -f $_.Exception.Message)
        if (Test-Path -LiteralPath $MsuMapCache) {
            Write-Log ("Using cached map: {0}" -f $MsuMapCache)
            try {
                $raw  = Get-Content -LiteralPath $MsuMapCache -Raw -ErrorAction Stop
                $json = $raw | ConvertFrom-Json -ErrorAction Stop
                return $json
            } catch {
                Write-Log ("Cached map is invalid: {0}. Exiting 113." -f $_.Exception.Message)
                exit 113
            }
        } else {
            Write-Log "No cached map available. Exiting 112."
            exit 112
        }
    }
}

function Ensure-PackagesArray {
    param(
        [Parameter(Mandatory)]$Entry,
        [Parameter(Mandatory)][string]$KeyForErrors
    )
    <#
      Accepts:
        - { "packages": [ { "url": "...", "type": "LCU", "order": 20 }, ... ] }
        - { "url": "..." }   (single package)
        - "https://..."      (single package as string)
      Returns: array of package objects with at least .url
    #>
    if ($Entry -is [string]) {
        if ($Entry -notmatch '^https?://') { throw "Invalid entry for build '$KeyForErrors': expected URL string." }
        return @(@{ url = $Entry; type = $null; order = $null })
    }

    $props = @($Entry.PSObject.Properties.Name)
    if ($props -contains 'packages') {
        $arr = @($Entry.packages)
        if (-not $arr -or $arr.Count -eq 0) { throw "Entry for build '$KeyForErrors' has empty 'packages'." }
        foreach ($p in $arr) {
            if (-not $p.url) { throw "One package in build '$KeyForErrors' is missing 'url'." }
        }
        return $arr
    }

    if ($props -contains 'url') {
        return @(@{ url = [string]$Entry.url; type = $Entry.type; order = $Entry.order })
    }

    throw "Invalid entry format for build '$KeyForErrors'. Expected 'packages' array or 'url' string/property."
}

function Sort-Packages {
    param([Parameter(Mandatory)][array]$Packages)
    # Priority: explicit 'order' asc, else by 'type' (SSU=10, LCU=20, NET=30, other=50)
    $prio = @{ 'SSU' = 10; 'LCU' = 20; 'NET' = 30 }
    return $Packages | Sort-Object `
        @{ Expression = { if ($_.order -ne $null -and "$($_.order)" -match '^\d+$') { [int]$_.order } else { 999 } } },
        @{ Expression = { $t = ("" + $_.type).ToUpper(); if ($prio.ContainsKey($t)) { $prio[$t] } else { 50 } } }
}

function Resolve-PackagesForBuild {
    param(
        [Parameter(Mandatory)]$BuildInfo,
        [Parameter(Mandatory)]$JsonMap,
        [string]$OverrideBuildFull
    )
    $key = if ([string]::IsNullOrWhiteSpace($OverrideBuildFull)) { $BuildInfo.BuildFull } else { $OverrideBuildFull }

    # Convert root object to hashtable keyed by build strings
    $map = @{}
    foreach ($p in $JsonMap.PSObject.Properties) { $map[$p.Name] = $p.Value }

    if (-not $map.ContainsKey($key)) { throw ("No MSU mapping defined for full build '{0}'." -f $key) }

    $entry    = $map[$key]
    $packages = Ensure-PackagesArray -Entry $entry -KeyForErrors $key
    $packages = Sort-Packages -Packages $packages
    return @{ Key=$key; Packages=$packages }
}

function Test-IsAdmin {
    $wi = [Security.Principal.WindowsIdentity]::GetCurrent()
    $wp = [Security.Principal.WindowsPrincipal]::new($wi)
    return $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Filename-FromUrl {
    param([Parameter(Mandatory)][string]$Url)
    try {
        $u = [Uri]$Url
        $name = [IO.Path]::GetFileName($u.AbsolutePath)
        if ([string]::IsNullOrWhiteSpace($name)) { $name = "update.msu" }
    } catch { $name = "update.msu" }
    if ($name -notmatch '\.msu$') { $name = "$name.msu" }
    return $name
}

# -------- Script start --------
if (-not (Test-IsAdmin)) { Write-Log "Warning: Script is not running elevated." }

# Build detection
$b = Get-BuildFull
Write-Log ("Detected OS: Build={0}" -f $b.BuildFull)

# Load mapping + resolve package list
$msuJson = Get-MSUMapFromJson
try {
    $sel = Resolve-PackagesForBuild -BuildInfo $b -JsonMap $msuJson -OverrideBuildFull $OverrideBuildFull
    Write-Log ("Selected {0} package(s) for Build={1}" -f $sel.Packages.Count, $sel.Key)
} catch {
    Write-Log ("MSU selection error: {0}. Exiting 111." -f $_.Exception.Message)
    exit 111
}

# Checks
try {
    $RebootRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    if (Test-Path $RebootRegKey) { Write-Log "Pending reboot detected. Exiting 101."; exit 101 }
} catch { Write-Log ("Error while checking free space: {0}" -f $_.Exception.Message); exit 199 }

try {
    $minFreeGB = 5
    $drive = Get-PSDrive -Name C -ErrorAction Stop
    $freeGB = [math]::Round(($drive.Free/1GB),2)
    if ($freeGB -lt $minFreeGB) { Write-Log ("Insufficient free space: required {0}GB, available {1}GB. Exiting 103." -f $minFreeGB, $freeGB); exit 103 }
} catch { Write-Log ("Error while checking free space: {0}" -f $_.Exception.Message); exit 198 }

# Download + install each package in order
$ScriptDir = "C:\Windows\Temp"
if (-not (Test-Path -LiteralPath $ScriptDir)) { New-Item -ItemType Directory -Path $ScriptDir -Force | Out-Null }

$anyNeedReboot = $false
$anyInstalled  = $false

foreach ($pkg in $sel.Packages) {
    $url      = [string]$pkg.url
    if ([string]::IsNullOrWhiteSpace($url)) { Write-Log "Package without URL encountered. Aborting (bad JSON)."; exit 113 }
    $type     = ("" + $pkg.type)
    $fileName = Filename-FromUrl -Url $url
    $destPath = Join-Path $ScriptDir $fileName

    Write-Log ("Downloading {0}{1} from {2}" -f (if ($type) { "[$type] " } else { "" }), $fileName, $url)
    try {
        $wc = New-Object System.Net.WebClient
        try {
            $wc.Headers['User-Agent'] = ("MSU-Installer/1.0 ({0})" -f $ComputerName)
            if (Test-Path -LiteralPath $destPath) { Remove-Item -LiteralPath $destPath -Force -ErrorAction Stop }
            $wc.DownloadFile($url, $destPath)
        } finally { if ($wc) { $wc.Dispose() } }
        if (-not (Test-Path -LiteralPath $destPath)) { Write-Log "Download failed: file not found after download. Exiting 104."; exit 104 }
    } catch {
        Write-Log ("Failed to download package {0}: {1}. Exiting 104." -f $fileName, $_.Exception.Message)
        exit 104
    }

    Write-Log ("Installing {0}{1}" -f (if ($type) { "[$type] " } else { "" }), $fileName)
    try {
        $proc = Start-Process -FilePath "wusa.exe" -ArgumentList "`"$destPath`" /quiet /norestart" -Wait -PassThru
        $code = $proc.ExitCode
        Write-Log ("wusa.exe exit code: {0} for {1}" -f $code, $fileName)

        if ($code -eq 3010) { $anyNeedReboot = $true; $anyInstalled = $true }
        elseif ($code -eq 0) { $anyInstalled = $true }
        elseif ($code -eq 2359302) { } # already installed, continue
        else {
            Write-Log ("Installation failed for {0} with code {1}. Aborting." -f $fileName, $code)
            exit $code
        }
    } catch {
        Write-Log ("Installation failed for {0}: {1}" -f $fileName, $_.Exception.Message)
        exit 195
    }
}

# Overall exit code policy
if    ($anyNeedReboot) { exit 3010 }
elseif ($anyInstalled) { exit 0 }
else                   { exit 2359302 }
