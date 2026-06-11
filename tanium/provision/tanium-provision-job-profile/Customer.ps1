<#
.SYNOPSIS
Adds Tanium tags based on the selected DemoLab provisioning profile.
#>

Import-Module C:\_T\TaniumOSD -ErrorAction Stop
Import-Module C:\_T\TaniumClient -ErrorAction Stop

$Profile = Get-OSDVariable -Name 'ProfileMetier'

if ([string]::IsNullOrWhiteSpace($Profile)) {
    Write-Host 'ProfileMetier is empty. No Tanium tag will be added.'
    exit 0
}

$CleanProfile = $Profile -replace '[^A-Za-z0-9_-]', '_'
$TagName = "Provision_$CleanProfile"

Add-TaniumTag -Tag 'OSD'
Add-TaniumTag -Tag $TagName

Write-Host 'Added Tanium tag: OSD'
Write-Host "Added Tanium tag: $TagName"
exit 0
