$VbootActive = 0
$logfile = "C:\ldprovisioning\ProvisionGUI.exe.log"
 
if (Test-Path $logfile) {
  $inf = Get-Content -path $logfile
  $lastActionError = "xxx"
  $display = 0
  foreach ($line in $inf) {
    if (($line -like "*SUCCESS*") -and ($line -like "*Vboot*")) { $VbootActive = 1 }
  }
}
 
if ($VbootActive -eq 1) { Add-Content -Path "C:\exploit\vbooton.flg" -Value "vboot" }