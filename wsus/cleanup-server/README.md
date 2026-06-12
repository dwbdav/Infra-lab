# WSUS Cleanup Server

Source article: to be linked when the matching blog post is published or identified.

## Purpose

Run a WSUS cleanup using the WSUS administration API.

## Files

- `Wsus-Cleanup.ps1` : PowerShell script that declines superseded/expired updates, removes obsolete updates/computers, compresses updates and deletes unneeded content files.

## Usage

```powershell
# Standard cleanup on localhost, HTTP 8530
.\Wsus-Cleanup.ps1 -Verbose

# HTTPS on 8531
.\Wsus-Cleanup.ps1 -UseSsl -Port 8531 -Verbose
```

## Requirements

- Run on the WSUS server as Administrator.
- WSUS PowerShell module `UpdateServices`, or the WSUS Admin DLL available at `%ProgramFiles%\Update Services\Tools\Microsoft.UpdateServices.Administration.dll`.
- Schedule outside business hours on large WSUS servers.

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or UNC path detected.
