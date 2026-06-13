# EPM Console Extender Right-Click Scripts

PowerShell scripts used as Ivanti EPM Console Extender right-click actions for device troubleshooting.

Source article: [Adding Scripts to the Console](https://blog.wuibaille.fr/2023/04/epm-ajout-de-scripts-dans-la-console/)

## Scripts

| Script | Purpose |
| --- | --- |
| `RightClickcleanRemote.ps1` | Removes temporary files, SDM cache, provisioning folders, and browser cache from a target computer. |
| `RightClickcleansdmcache.ps1` | Cleans SDM cache and deployment cache folders from a target computer. |
| `RightClickHistoriquePC.ps1` | Exports reliability history from a target computer. |
| `RightClickLogLANDESK.ps1` | Collects Ivanti/LANDESK client logs and preferred server information from a target computer. |

## Usage

Each script expects the EPM console variable for the selected device name:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\RightClickLogLANDESK.ps1 -Mycomputer "<Computer.Device Name>"
```

## Notes

- These scripts require administrative access to the target computer.
- Cleanup scripts remove files from remote admin shares such as `\\computer\c$`.
- Review the cleanup paths before deploying them in a production console.
