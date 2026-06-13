# Report Top WSUS Error Computers

Find the top computers with the most Windows Update error events in WSUS over a recent time window, list their failed updates, and export the result to CSV.

Source article: TBD

## Script

| Script | Purpose |
| --- | --- |
| `Top-ErrorComputers.ps1` | Aggregates WSUS error events per computer and displays the top failing clients. |

## Requirements

- Run on the WSUS server.
- Use an elevated 64-bit Windows PowerShell session.
- WSUS PowerShell module `UpdateServices`, or the WSUS administration DLL:
  `C:\Program Files\Update Services\Tools\Microsoft.UpdateServices.Administration.dll`

## Configuration

Edit the variables at the top of the script:

```powershell
$Days   = 7
$Top    = 10
$OutCsv = "$PSScriptRoot\WSUS_FailedComputers_{0:yyyyMMdd}.csv" -f (Get-Date)
```

## Usage

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Top-ErrorComputers.ps1
```

## Output

- Console table with `ComputerName`, `IPAddress`, `Errors`, and `LastError`.
- CSV file at the path defined by `$OutCsv`.
- Failed update titles listed for each top computer.
