# WSUS Database Maintenance

Source article: to be linked when the matching blog post is published or identified.

## Purpose

Connect to the WSUS `SUSDB` database and run maintenance tasks such as index rebuild/reorganize and statistics update.

## Files

- `Maintenance.sql` : SQL script that checks index fragmentation, rebuilds or reorganizes indexes, and runs `sp_updatestats`.

## WID connection

Run tools locally on the WSUS server as Administrator.

```text
Server name: \\.\pipe\MICROSOFT##WID\tsql\query
Database: SUSDB
Authentication: Windows Authentication
```

## PowerShell example

```powershell
Import-Module SqlServer

$Instance = "\\.\pipe\MICROSOFT##WID\tsql\query"
$Database = "SUSDB"
$FileSql = ".\Maintenance.sql"

Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -InputFile $FileSql -AbortOnError
```

## sqlcmd example

```bat
sqlcmd -S np:\\.\pipe\MICROSOFT##WID\tsql\query -d SUSDB -i Maintenance.sql -b
```

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or public credential detected.
- WID named pipe paths are documented local WSUS connection strings.
