# Uninstall KB With PSWindowsUpdate

Remove an installed Windows update by KB number using the `PSWindowsUpdate` PowerShell module.

Source article: TBD

## Script

| Script | Purpose |
| --- | --- |
| `Remove-KB.ps1` | Checks whether a KB is installed, then calls `Remove-WindowsUpdate`. |
| `uninstallKB.ps1` | Original script variant using `Remove-WindowsUpdate`. |

## Requirements

- Run PowerShell as Administrator.
- The repository includes the original `PSWindowsUpdate\2.2.0.3` module copy from the source folder.
- You can also install or update the module from PowerShell Gallery if preferred:

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
- Review the KB number before running the removal script on production devices.
