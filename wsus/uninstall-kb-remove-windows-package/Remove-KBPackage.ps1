#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory)]
    [ValidatePattern('^(?i:KB)?\d+$')]
    [string]$KB,

    [switch]$NoRestart
)

if ($KB -match '^\d+$') {
    $KB = "KB$KB"
}

$packages = Get-WindowsPackage -Online | Where-Object { $_.PackageName -match [regex]::Escape($KB) }

if (-not $packages) {
    Write-Host "No packages found matching $KB."
    return
}

Write-Host "Packages found matching $KB:"
$packages | ForEach-Object { Write-Host " - $($_.PackageName)" }

foreach ($package in $packages) {
    try {
        Write-Host "Uninstalling $($package.PackageName)..."
        $params = @{
            Online      = $true
            PackageName = $package.PackageName
            ErrorAction = 'Stop'
        }
        if ($NoRestart) {
            $params['NoRestart'] = $true
        }

        Remove-WindowsPackage @params
        Write-Host "$($package.PackageName) uninstalled successfully."
    }
    catch {
        Write-Error "Failed to uninstall $($package.PackageName). Error: $($_.Exception.Message)"
    }
}

if ($NoRestart) {
    Write-Host "Restart is deferred. Reboot the computer later to complete removal if required."
}
else {
    Write-Host "A restart may be required."
}
