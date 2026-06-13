#requires -version 5.1
<#
  Auto-install latest OS cumulative updates using PSWindowsUpdate (no JSON)
  - Forces Windows Update public service (-WindowsUpdate)
  - Installs SSU (if present) first, then latest non-Preview LCU
  - ASCII-only logs; messages sanitized before sending to web service
#>

# -------- Settings --------
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

$ComputerName = $env:COMPUTERNAME
$LogPath      = "C:\Windows\Temp\MSU_Install.log"
$ApiUrl       = "https://nas.wuibaille.fr/WS/message.php"
$SendLogsToWS = $true

# Optional WS retry tunables (defaults: 6 tries, 1s delay)
$script:WsMaxRetries    = 6
$script:WsRetryDelaySec = 1

# Module install policy
$AllowInstallPSWindowsUpdate = $true

# -------- Utilities --------
function Sanitize-Ascii {
    param([string]$Text)
    if ($null -eq $Text) { return "" }

    $t = $Text
    $t = $t -replace [char]0x2013, "-"   # en dash
    $t = $t -replace [char]0x2014, "-"   # em dash
    $t = $t -replace [char]0x2026, "..." # ellipsis
    $t = $t -replace [char]0x2018, "'"   # left single quote
    $t = $t -replace [char]0x2019, "'"   # right single quote
    $t = $t -replace [char]0x201C, '"'   # left double quote
    $t = $t -replace [char]0x201D, '"'   # right double quote
    $t = $t -replace [char]0x00A0, " "   # nbsp
    $t = $t -replace [char]0x2022, "-"   # bullet
    $t = [System.Text.RegularExpressions.Regex]::Replace($t, '[^\x09\x0A\x0D\x20-\x7E]', '')
    return $t
}

# -------- Logging --------
function Write-Log {
    param([Parameter(Mandatory)][string]$Message)

    $msg  = Sanitize-Ascii $Message
    $full = "[$env:COMPUTERNAME] $msg"
    $ts   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Add-Content -Path $LogPath -Value "$ts $full" -Encoding UTF8
    Write-Host $full

    if (-not $SendLogsToWS) { return }

    $payload = @{ message = $full } | ConvertTo-Json -Compress
    $bytes   = [System.Text.Encoding]::UTF8.GetBytes($payload)

    $max   = if ($script:WsMaxRetries)    { [int]$script:WsMaxRetries }    else { 6 }
    $delay = if ($script:WsRetryDelaySec) { [int]$script:WsRetryDelaySec } else { 1 }

    $ok = $false
    $lastErr = $null

    for ($attempt = 1; $attempt -le $max -and -not $ok; $attempt++) {
        try {
            $null = Invoke-RestMethod -Uri $ApiUrl -Method POST -Body $bytes `
                    -ContentType 'application/json; charset=utf-8' -TimeoutSec 10 -ErrorAction Stop
            $ok = $true
        } catch {
            $lastErr = $_.Exception.Message
            if ($attempt -lt $max) { Start-Sleep -Seconds $delay }
        }
    }

    if (-not $ok) {
        Write-Warning "[$env:COMPUTERNAME] Webservice log failed after $max attempts: $lastErr"
    }
}

# -------- Prereqs --------
function Test-IsAdmin {
    $wi = [Security.Principal.WindowsIdentity]::GetCurrent()
    $wp = [Security.Principal.WindowsPrincipal]::new($wi)
    return $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-BuildFull {
    $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $buildStr = [string]$cv.CurrentBuild
    if ([string]::IsNullOrWhiteSpace($buildStr)) { $buildStr = [string]$cv.CurrentBuildNumber }
    $major = [int]$buildStr
    $ubr = 0; try { $ubr = [int]$cv.UBR } catch {}
    [PSCustomObject]@{ BuildMajor=$major; UBR=$ubr; BuildFull=("{0}.{1}" -f $major,$ubr) }
}

# -------- PSWindowsUpdate bootstrap (silent) --------
function Ensure-PSWindowsUpdate {
    try {
        Import-Module PSWindowsUpdate -ErrorAction Stop
        $m = Get-Module PSWindowsUpdate
        Write-Log ("PSWindowsUpdate module loaded (v{0})." -f $m.Version)
        return $true
    } catch {}

    if (-not $AllowInstallPSWindowsUpdate) {
        Write-Log "PSWindowsUpdate module not found and auto-install is disabled. Exiting 120."
        exit 120
    }

    $scope = if (Test-IsAdmin) { 'AllUsers' } else { 'CurrentUser' }

    try {
        $nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue |
                 Sort-Object Version -Descending | Select-Object -First 1
        if (-not $nuget -or ([Version]$nuget.Version -lt [Version]"2.8.5.201")) {
            Write-Log "Installing NuGet provider silently..."
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope $scope -ErrorAction Stop
        }

        $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        if (-not $repo) {
            Write-Log "Registering PSGallery repository..."
            try { Register-PSRepository -Default -ErrorAction Stop } catch {}
            $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        }
        if ($repo -and $repo.InstallationPolicy -ne 'Trusted') {
            Write-Log "Setting PSGallery as Trusted..."
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        }

        try {
            $psget = Get-Module -ListAvailable PowerShellGet | Sort-Object Version -Descending | Select-Object -First 1
            if (-not $psget -or ([Version]$psget.Version -lt [Version]"2.2.5")) {
                Write-Log "Updating PowerShellGet silently..."
                Install-Module PowerShellGet -Scope $scope -Force -AllowClobber -ErrorAction Stop
            }
        } catch {
            Write-Log ("PowerShellGet update failed (continuing): {0}" -f $_.Exception.Message)
        }

        Write-Log "Installing PSWindowsUpdate silently..."
        Install-Module PSWindowsUpdate -Scope $scope -Force -AllowClobber -ErrorAction Stop

        Import-Module PSWindowsUpdate -ErrorAction Stop
        $m = Get-Module PSWindowsUpdate
        Write-Log ("PSWindowsUpdate installed and loaded (v{0})." -f $m.Version)
        return $true
    } catch {
        Write-Log ("Failed to install/load PSWindowsUpdate: {0}. Exiting 120." -f $_.Exception.Message)
        exit 120
    }
}

# -------- Discovery & Install using PSWindowsUpdate --------
function Get-AvailableOSUpdates {
    # Returns: @{ SSU = <update or $null>; LCU = <update or $null>; Raw = <array> }
    try {
        $raw = Get-WindowsUpdate -WindowsUpdate -UpdateType Software -IgnoreReboot -ErrorAction Stop
    } catch {
        Write-Log ("Windows Update query failed: {0}" -f $_.Exception.Message)
        Write-Log "This system may be WSUS-managed or blocked by policy/network. Exiting 121."
        exit 121
    }

    if (-not $raw) {
        return [PSCustomObject]@{ SSU=$null; LCU=$null; Raw=@() }
    }

    $filtered = $raw | Where-Object {
        $_.Title -and
        ($_.Title -notmatch 'Preview') -and
        ($_.Title -notmatch 'for\s*\.NET') -and
        ($_.Categories -notcontains 'Drivers') -and
        ($_.Categories -notcontains 'Definition Updates')
    }

    $norm = {
        param($s)
        if (-not $s) { return '' }
        $t = Sanitize-Ascii $s
        return $t.ToLowerInvariant()
    }

    $ssu = $filtered | Where-Object {
        $t = & $norm $_.Title
        ($t -match 'servicing stack update' -or $t -match 'pile de maintenance')
    } | Sort-Object -Property LastDeploymentChangeTime -Descending | Select-Object -First 1

    $lcu = $filtered | Where-Object {
        $t = & $norm $_.Title
        ($t -match 'cumulative update' -or $t -match 'mise a jour cumulative')
    } | Sort-Object -Property LastDeploymentChangeTime -Descending | Select-Object -First 1

    [PSCustomObject]@{ SSU=$ssu; LCU=$lcu; Raw=$filtered }
}

function Install-OneWU {
    param([Parameter(Mandatory)]$UpdateObject)

    $updateId = $UpdateObject.UpdateID
    $title    = Sanitize-Ascii $UpdateObject.Title
    $kb       = $UpdateObject.KB

    $kbPrefix = if ($kb) { "$kb " } else { "" }
    Write-Log ("Installing: {0}{1}" -f $kbPrefix, $title)

    try {
        if ($updateId) {
            $res = Install-WindowsUpdate -WindowsUpdate -UpdateID $updateId -AcceptAll -IgnoreReboot -Confirm:$false -ErrorAction Stop
        } elseif ($kb) {
            $res = Install-WindowsUpdate -WindowsUpdate -KBArticleID $kb -AcceptAll -IgnoreReboot -Confirm:$false -ErrorAction Stop
        } else {
            $res = Install-WindowsUpdate -WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$false -ErrorAction Stop |
                   Where-Object { (Sanitize-Ascii $_.Title) -eq $title }
        }
    } catch {
        Write-Log ("Install failed for {0}{1}: {2}" -f $kbPrefix, $title, $_.Exception.Message)
        return [PSCustomObject]@{
            Title = $title; KB = $kb; Result = 'Failed'; HResult = $null; RebootRequired = $false
        }
    }

    # Build a clean result array without inline 'if'
    $out = @()
    foreach ($o in @($res)) {
        $rTitle = Sanitize-Ascii $o.Title

        $rKB = $null
        if ($o.PSObject.Properties['KB'] -and $o.KB) { $rKB = $o.KB }
        elseif ($o.PSObject.Properties['KBArticleID'] -and $o.KBArticleID) { $rKB = $o.KBArticleID }

        $rResult = $null
        if ($o.PSObject.Properties['Result'] -and $o.Result) { $rResult = $o.Result } else { $rResult = $o.ResultCode }

        $rHResult = $null
        if ($o.PSObject.Properties['HResult']) { $rHResult = $o.HResult }

        $rReboot = $false
        if ($o.PSObject.Properties['RebootRequired']) { $rReboot = [bool]$o.RebootRequired }

        $out += [PSCustomObject]@{
            Title          = $rTitle
            KB             = $rKB
            Result         = $rResult
            HResult        = $rHResult
            RebootRequired = $rReboot
        }
    }
    return ,$out  # ensure array even if single item
}

# =================== Main ===================
if (-not (Test-IsAdmin)) { Write-Log "Warning: script is not running elevated." }

try {
    $RebootRegKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    if (Test-Path $RebootRegKey) { Write-Log "Pending reboot detected. Exiting 101."; exit 101 }
} catch { Write-Log ("Error while checking pending reboot: {0}" -f $_.Exception.Message); exit 199 }

try {
    $minFreeGB = 5
    $drive = Get-PSDrive -Name C -ErrorAction Stop
    $freeGB = [math]::Round(($drive.Free/1GB),2)
    if ($freeGB -lt $minFreeGB) { Write-Log ("Insufficient free space: required {0}GB, available {1}GB. Exiting 103." -f $minFreeGB, $freeGB); exit 103 }
} catch { Write-Log ("Error while checking free space: {0}" -f $_.Exception.Message); exit 198 }

$build = Get-BuildFull
Write-Log ("Detected OS: Build={0}" -f $build.BuildFull)

Ensure-PSWindowsUpdate | Out-Null

$updates = Get-AvailableOSUpdates

# Plan (pre-calc strings to avoid inline if in -f)
if ($updates.SSU) {
    $kbPrefix = if ($updates.SSU.KB) { "$($updates.SSU.KB) " } else { "" }
    $title    = Sanitize-Ascii $updates.SSU.Title
    Write-Log ("Plan: SSU -> {0}{1}" -f $kbPrefix, $title)
}
if ($updates.LCU) {
    $kbPrefix = if ($updates.LCU.KB) { "$($updates.LCU.KB) " } else { "" }
    $title    = Sanitize-Ascii $updates.LCU.Title
    Write-Log ("Plan: LCU -> {0}{1}" -f $kbPrefix, $title)
}

if (-not $updates.SSU -and -not $updates.LCU) {
    Write-Log "No OS SSU/LCU updates available (system appears up-to-date)."
    exit 0
}

$needReboot = $false
$installed  = $false
$failedAny  = $false

if ($updates.SSU) {
    $r = Install-OneWU -UpdateObject $updates.SSU
    foreach ($i in @($r)) {
        $kbPrefix = if ($i.KB) { "$($i.KB) " } else { "" }
        $hrSuf    = if ($i.HResult) { " (HResult=$($i.HResult))" } else { "" }
        $rbSuf    = if ($i.RebootRequired) { " [RebootRequired]" } else { "" }
        Write-Log ("Result: {0}{1} => {2}{3}{4}" -f $kbPrefix, $i.Title, $i.Result, $hrSuf, $rbSuf)

        if ($i.Result -match 'Succeeded') { $installed = $true }
        elseif ($i.Result -match 'Failed|Aborted|Error') { $failedAny = $true }
        if ($i.RebootRequired) { $needReboot = $true }
    }
}

if ($updates.LCU) {
    $r = Install-OneWU -UpdateObject $updates.LCU
    foreach ($i in @($r)) {
        $kbPrefix = if ($i.KB) { "$($i.KB) " } else { "" }
        $hrSuf    = if ($i.HResult) { " (HResult=$($i.HResult))" } else { "" }
        $rbSuf    = if ($i.RebootRequired) { " [RebootRequired]" } else { "" }
        Write-Log ("Result: {0}{1} => {2}{3}{4}" -f $kbPrefix, $i.Title, $i.Result, $hrSuf, $rbSuf)

        if ($i.Result -match 'Succeeded') { $installed = $true }
        elseif ($i.Result -match 'Failed|Aborted|Error') { $failedAny = $true }
        if ($i.RebootRequired) { $needReboot = $true }
    }
}

if ($failedAny) { Write-Log "One or more updates failed."; exit 195 }
if ($needReboot) { exit 3010 }
if ($installed)  { exit 0 }
exit 0
