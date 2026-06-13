# Check Missing EPM Package Files

Validate that Ivanti EPM package file references still exist for HTTP/HTTPS and UNC package paths.

Source article: [Deploy - change paths in SQL with Ivanti EPM](https://blog.wuibaille.fr/2023/04/epm-changement-des-chemins-des-packages-en-bdd/)

## Script

| Script | Purpose |
| --- | --- |
| `Check-EpmPackageFiles.ps1` | Reads EPM package file references from SQL and reports missing HTTP/HTTPS or UNC files. |

## Requirements

- Windows PowerShell 5.1.
- SQL read access to the EPM database.
- Read access to the package file locations being checked.

## Usage

```powershell
$credential = Get-Credential

.\Check-EpmPackageFiles.ps1 `
  -SqlServer "sql.example.local" `
  -Database "EPM2021" `
  -Credential $credential
```

The script writes missing package references to the pipeline and exits with code `1` when missing files are found.

## Notes

- SQL credentials are passed with `Get-Credential`; no password is stored in the script.
- HTTP/HTTPS paths are tested with `Invoke-WebRequest -Method Head`.
- UNC paths are tested with `Test-Path`.
