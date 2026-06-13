<#
.SYNOPSIS
  Fast download & silent install of Google Chrome Enterprise MSI (auto-arch).
.DESCRIPTION
  Tries curl.exe (fast), then BITS (robust), then Invoke-WebRequest as fallback.
  No version checks. Always installs. Retries & timeouts included.
#>

$ErrorActionPreference = 'Stop'

# -------- Config --------
$Is64OS = [Environment]::Is64BitOperatingSystem
$Arch   = if ($Is64OS) { 'x64' } else { 'x86' }
$Url64  = 'https://dl.google.com/chrome/install/GoogleChromeStandaloneEnterprise64.msi'
$Url32  = 'https://dl.google.com/chrome/install/GoogleChromeStandaloneEnterprise.msi'
$Url    = if ($Arch -eq 'x64') { $Url64 } else { $Url32 }

$OutFile = Join-Path $env:TEMP ("GoogleChrome_Enterprise_{0}.msi" -f $Arch)
$MaxRetries   = 3
$TimeoutSec   = 120   # per attempt (curl/IWR)
$BitsTimeoutS = 300   # global timeout for BITS attempt
$RetryDelayS  = 3

# (Optional) Proxy if needed
# $env:HTTPS_PROXY = 'http://proxy.example.local:8080'
# $env:HTTP_PROXY  = 'http://proxy.example.local:8080'

# -------- Helpers --------
function Test-FileValid([string]$Path){
    if (-not (Test-Path $Path)) { return $false }
    try {
        $fi = Get-Item $Path -ErrorAction Stop
        return ($fi.Length -gt 1MB)  # Chrome MSI is ~100+ MB; change if needed
    } catch { return $false }
}

function Download-WithCurl([string]$Url,[string]$Dst,[int]$TimeoutSec){
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $curl) { return $false }
    # -L follow redirects, --fail to fail on HTTP errors, --max-time timeout seconds
    $args = @('-L', '--fail', '--max-time', $TimeoutSec, '-o', $Dst, $Url)
    $p = Start-Process -FilePath $curl.Source -ArgumentList $args -Wait -PassThru -WindowStyle Hidden
    return ($p.ExitCode -eq 0 -and (Test-FileValid $Dst))
}

function Download-WithBITS([string]$Url,[string]$Dst,[int]$TimeoutS){
    # Foreground = plus rapide que background (throttling OS réduit)
    try {
        if (Test-Path $Dst) { Remove-Item $Dst -Force -ErrorAction SilentlyContinue }
        $job = Start-BitsTransfer -Source $Url -Destination $Dst -Priority Foreground -Asynchronous -ErrorAction Stop
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($job.JobState -in 'Connecting','Transferring','Queued') {
            Start-Sleep -Seconds 1
            $job = Get-BitsTransfer -Id $job.Id -ErrorAction SilentlyContinue
            if ($sw.Elapsed.TotalSeconds -gt $TimeoutS) {
                Remove-BitsTransfer -BitsJob $job -ErrorAction SilentlyContinue
                throw "BITS timeout after ${TimeoutS}s"
            }
        }
        if ($job.JobState -eq 'Transferred') {
            Complete-BitsTransfer -BitsJob $job -ErrorAction Stop
        } else {
            throw "BITS failed with state: $($job.JobState)"
        }
        return (Test-FileValid $Dst)
    } catch {
        return $false
    }
}

function Download-WithIWR([string]$Url,[string]$Dst,[int]$TimeoutSec){
    try {
        if (Test-Path $Dst) { Remove-Item $Dst -Force -ErrorAction SilentlyContinue }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        Invoke-WebRequest -Uri $Url -OutFile $Dst -UseBasicParsing -TimeoutSec $TimeoutSec
        return (Test-FileValid $Dst)
    } catch { return $false }
}

function Download-Fast([string]$Url,[string]$Dst){
    for ($i=1; $i -le $MaxRetries; $i++) {
        Write-Host "Attempt $i/$MaxRetries with curl.exe ..."
        if (Download-WithCurl $Url $Dst $TimeoutSec) { return $true }
        Write-Host "curl.exe failed. Trying BITS ..."
        if (Download-WithBITS $Url $Dst $BitsTimeoutS) { return $true }
        Write-Host "BITS failed. Trying Invoke-WebRequest ..."
        if (Download-WithIWR $Url $Dst $TimeoutSec) { return $true }
        Write-Warning "All methods failed (attempt $i). Retrying in ${RetryDelayS}s..."
        Start-Sleep -Seconds $RetryDelayS
    }
    return $false
}

# -------- Download & Install --------
Write-Host "Downloading Chrome $Arch from $Url"
if (-not (Download-Fast $Url $OutFile)) {
    throw "Download failed after $MaxRetries attempts."
}

Write-Host "Installing Chrome $Arch silently..."
$msiArgs = @('/i', "`"$OutFile`"", '/qn', '/norestart')
$proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru
switch ($proc.ExitCode) {
    0    { Write-Host "Chrome $Arch installed successfully." }
    3010 { Write-Host "Chrome $Arch installed. Reboot required (3010)." }
    default { throw "msiexec exited with $($proc.ExitCode)" }
}

# Optional cleanup:
Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
