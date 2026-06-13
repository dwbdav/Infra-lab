# Reporting Dashboard with PSWriteHTML

PowerShell examples used to generate HTML dashboards from Ivanti EPM SQL inventory data with the `PSWriteHTML` module.

Source article: [Create a dashboard with PswriteHTML with Ivanti EPM](https://blog.wuibaille.fr/2024/09/report-html-with-epm/)

## Files

| File | Description |
| --- | --- |
| `report.ps1` | Basic PSWriteHTML dashboard example using Ivanti EPM SQL data. |
| `SuiviMigrationWindows.ps1` | Windows migration tracking dashboard with version history and charts. |

## Requirements

Install the required PowerShell module:

```powershell
Install-Module PSWriteHTML -Scope CurrentUser -Force
```

The scripts require SQL access to the Ivanti EPM database.

## Configuration

`report.ps1` contains lab values:

```powershell
$ServerSQL = "epm2024.monlab.lan"
$database = "EPM"
$user = "sa"
$password = "Password1"
```

Replace them before production use. `Password1` is a lab placeholder and should not be reused.

`SuiviMigrationWindows.ps1` reads SQL settings from:

```powershell
C:\Scripts\config.json
```

Expected structure:

```json
{
  "SQL": {
    "Server": "epm2024.monlab.lan",
    "Database": "EPM",
    "Username": "report_user",
    "Password": "Password1"
  }
}
```

## Output

The scripts generate an HTML dashboard:

```powershell
C:\temp\default.htm
```

or, for the migration tracking script:

```powershell
C:\Exploitation\WSUS\default.htm
```

Adapt these paths to your reporting or IIS virtual directory.

## Notes

- Store production credentials securely, for example with Windows Credential Manager, DPAPI, or a vault.
- `report.ps1` includes a simple lab credential example for demonstration.
- `SuiviMigrationWindows.ps1` maintains a local `windows_versions_history.csv` file next to the script.
