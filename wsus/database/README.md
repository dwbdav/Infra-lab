# WSUS Database

Source article: [Move the WSUS Integrated SUSDB Database](https://blog.wuibaille.fr/2023/04/deplacer-la-bdd-integre-de-wsus/)

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

For a standard SQL Server instance:

```powershell
Invoke-Sqlcmd -ServerInstance "localhost" -Database "SUSDB" -InputFile ".\Maintenance.sql" -AbortOnError
```

## sqlcmd example

```bat
sqlcmd -S np:\\.\pipe\MICROSOFT##WID\tsql\query -d SUSDB -i Maintenance.sql -b
```

For a standard SQL Server instance:

```bat
sqlcmd -S localhost -d SUSDB -i Maintenance.sql -b
```

## Schedule example

```powershell
schtasks /Create /TN "WSUS DB Maintenance" ^
  /TR "powershell.exe -NoProfile -Command Invoke-Sqlcmd -ServerInstance 'np:\\.\pipe\MICROSOFT##WID\tsql\query' -Database SUSDB -InputFile C:\Scripts\WSUSDBMaintenance.sql -AbortOnError" ^
  /SC MONTHLY /D 1 /ST 02:00 /RU "SYSTEM" /RL HIGHEST /F
```

## Notes

- Run off-hours.
- Back up `SUSDB` before maintenance.
- The source `public\WSUS\sql-maintenance` folder contains the same `Maintenance.sql` script and has been consolidated here to avoid duplicate WSUS database folders.

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or public credential detected.
- WID named pipe paths are documented local WSUS connection strings.
