# Uninstall KB With PSWindowsUpdate

Remove an installed Windows update by KB number using the `PSWindowsUpdate` PowerShell module.

Source article: TBD

## Script

| Script | Purpose |
| --- | --- |
| `Remove-KB.ps1` | Checks whether a KB is installed, then calls `Remove-WindowsUpdate`. |

## Requirements

- Run PowerShell as Administrator.
- Install the `PSWindowsUpdate` module if it is not already available:

```powershell
Install-Module PSWindowsUpdate -Scope CurrentUser
```

## Usage

```powershell
.\Remove-KB.ps1 -KB KB5028952 -NoRestart
```

You can also pass the KB number without the `KB` prefix:

```powershell
.\Remove-KB.ps1 -KB 5028952 -NoRestart
```

## Direct Commands

```powershell
Get-WindowsUpdate -IsInstalled -KBArticleID KB5028952
Remove-WindowsUpdate -KBArticleID KB5028952 -NoRestart -Confirm:$false
```

## Notes

- Some updates, especially Servicing Stack Updates, cannot be uninstalled.
- A restart may be required after removal.
- The source folder contained a local copy of the `PSWindowsUpdate` module; it is intentionally not published here.
