# Reset Windows Update Agent

PowerShell scripts to reset the Windows Update client cache when scan, download, or install states are stuck.

## Scripts

| Script | Purpose | Impact |
| --- | --- | --- |
| `CleanLight.ps1` | Removes the local Windows Update download and datastore cache. | Fast cleanup, usually enough for common client-side issues. |
| `CleanFull.ps1` | Renames `SoftwareDistribution` and `catroot2` after stopping update-related services. | Deeper reset, first scan after execution can take longer. |

## Usage

Run from an elevated 64-bit PowerShell session.

```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\CleanLight.ps1

C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\CleanFull.ps1
```

## Logs

- `CleanLight.ps1`: `C:\Windows\Temp\Wuauserv_Cleanup.log`
- `CleanFull.ps1`: `C:\Windows\Temp\WUA_Reset.log`

## Notes

- Both scripts reset the local Windows Update history view.
- Close the Windows Update settings page before running the scripts.
- After the reset, trigger a new scan or wait for the next scheduled scan.
