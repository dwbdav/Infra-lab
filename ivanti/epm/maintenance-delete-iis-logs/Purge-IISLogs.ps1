$LogPath = "C:\inetpub\logs\LogFiles\W3SVC1"
$maxDaystoKeep = -45
$outputPath = "C:\windows\temp\Purge_log_iis.log"
 
$itemsToDelete = dir $LogPath -File *.log | Where LastWriteTime -lt ((get-date).AddDays($maxDaystoKeep))
$itemsToDelete.VersionInfo.FileName
if ($itemsToDelete.Count -gt 0){
    ForEach ($item in $itemsToDelete){
        "$($item.BaseName) is older than $((get-date).AddDays($maxDaystoKeep)) and will be deleted" | Add-Content $outputPath
        Get-item $item.VersionInfo.FileName | Remove-Item -Verbose
    }
}
ELSE{
    "No items to be deleted today $($(Get-Date).DateTime)"  | Add-Content $outputPath
    }
 
Write-Output "Cleanup of log files older than $((get-date).AddDays($maxDaystoKeep)) completed..."
start-sleep -Seconds 10