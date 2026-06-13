# Purge IIS Logs

PowerShell script used to remove old IIS log files and prevent the system drive from filling up on an Ivanti EPM server or any IIS server.

## Files

| File | Description |
| --- | --- |
| `Purge-IISLogs.ps1` | Deletes IIS `.log` files older than the configured retention period. |
| `readme.png` | Example Task Scheduler configuration. |

## Configuration

Edit these variables in `Purge-IISLogs.ps1` before deployment:

```powershell
$LogPath = "C:\inetpub\logs\LogFiles\W3SVC1"
$maxDaystoKeep = -45
$outputPath = "C:\windows\temp\Purge_log_iis.log"
```

`$maxDaystoKeep` is intentionally negative because the script uses `Get-Date).AddDays(...)` to calculate the retention threshold.

## Usage

Run from an elevated PowerShell prompt on the IIS server:

```powershell
.\Purge-IISLogs.ps1
```

## Scheduled Task Example

Example weekly task running as `SYSTEM`:

```cmd
schtasks /Create /TN "IIS Logs Purge" ^
  /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\Purge-IISLogs.ps1" ^
  /SC WEEKLY /D SUN /ST 02:00 /RU SYSTEM /RL HIGHEST /F
```

![Task Scheduler example](readme.png)

## Notes

- Review `$LogPath` before running the script.
- The script writes an execution log to `$outputPath`.
- Test manually once before scheduling automatic deletion.
