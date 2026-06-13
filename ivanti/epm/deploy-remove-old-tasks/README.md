# Remove Old EPM Scheduled Tasks

Delete old Ivanti EPM scheduled tasks based on `dbo.LD_TASK.NEXT_START`, with name-based exclusions.

Source article: TBD

## Script

| Script | Purpose |
| --- | --- |
| `Remove-OldScheduledTasks.ps1` | Reads scheduled tasks from SQL and deletes old tasks through the Ivanti MBSDK web service. |

## Usage

Run with `-WhatIf` first:

```powershell
$sqlCredential = Get-Credential -Message "SQL read credential"
$epmCredential = Get-Credential -Message "Ivanti EPM MBSDK credential"

.\Remove-OldScheduledTasks.ps1 `
  -SqlServer "sql.example.local" `
  -Database "LDMS" `
  -SqlCredential $sqlCredential `
  -WebServiceUrl "https://epm.example.local/MBSDKService/MsgSDK.asmx?WSDL" `
  -EpmCredential $epmCredential `
  -RetentionDays 30 `
  -WhatIf
```

Remove `-WhatIf` only after reviewing the planned deletions.

## Defaults

Excluded task name patterns:

- `*PORTAL*`
- `*Download patch content*`

## Notes

- The source script contained lab SQL credentials and an EPM web service URL; those defaults were removed.
- This script deletes scheduled tasks, so use `-WhatIf` before running it for real.
