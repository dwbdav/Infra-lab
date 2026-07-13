# Generate Windows Update Log

Generate a readable `WindowsUpdate.log` file from Windows Update ETL traces.

Source article: [Tanium Patch Troubleshooting and Deployment Checks](https://blog.infra-lab.fr/2025/07/tanium-patch/)

## Command

Run from an elevated PowerShell session:

```powershell
Get-WindowsUpdateLog
```

By default, the generated `WindowsUpdate.log` file is created on the current user's desktop.

## Notes

- On Windows 10 and Windows 11, Windows Update logs are stored as ETL traces.
- `Get-WindowsUpdateLog` merges those traces into a readable log file.
- Use this log together with `C:\Windows\Logs\CBS\CBS.log` and `C:\Windows\SoftwareDistribution\ReportingEvents.log` when troubleshooting update failures.
