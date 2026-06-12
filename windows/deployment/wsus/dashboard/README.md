# WSUS Dashboard

Source article: https://blog.wuibaille.fr/2024/10/creating-a-wsus-dashboard/

## Purpose

Generate a single-page HTML dashboard for WSUS with target-group inventory, KB deployment status, approval timelines, per-KB computer status and failed update details.

## Files

- `Wsus-Report.ps1` : PowerShell script that reads WSUS data and generates the HTML report.

## Requirements

- Run on the WSUS server as Administrator.
- PowerShell module `PSWriteHTML`.
- WSUS Admin DLL at `%ProgramFiles%\Update Services\Tools\Microsoft.UpdateServices.Administration.dll`.
- Internet access for online report assets, unless you remove the `-Online` flag.

## Usage

```powershell
Install-Module PSWriteHTML -Scope CurrentUser

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Wsus-Report.ps1
```

Default output:

```text
C:\exploit\report\default.htm
```

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or UNC path detected.
