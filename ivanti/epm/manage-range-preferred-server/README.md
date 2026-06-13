# Manage Preferred Server IP Ranges

Generate SQL statements to add or remove IP ranges from Ivanti EPM preferred servers.

Source article: [Server - Preferred Server with Ivanti EPM](https://blog.wuibaille.fr/2023/04/epm-gestion-des-preferred-server/)

## Script

| Script | Purpose |
| --- | --- |
| `New-PreferredServerIpSql.ps1` | Loads preferred server ranges from SQL and exposes helper functions that generate SQL statements. |

## Usage

```powershell
$credential = Get-Credential

. .\New-PreferredServerIpSql.ps1 `
  -SqlServer "sql.example.local" `
  -Database "EPM2021" `
  -Credential $credential

New-RemoveAllPreferredServerIpSql -PreferredServerName "epm.example.local"

New-AddPreferredServerIpSql `
  -PreferredServerName "epm.example.local" `
  -StartAddress "192.168.0.1" `
  -EndAddress "192.168.0.254"

New-RemovePreferredServerIpSql `
  -PreferredServerName "epm.example.local" `
  -StartAddress "192.168.0.1" `
  -EndAddress "192.168.0.254"
```

## Notes

- The script generates SQL only; it does not execute the generated statements.
- SQL credentials are provided with `Get-Credential`.
- Ivanti stores IP addresses in this table as padded IPv4 strings such as `192.168.000.001`.
