# Uninstall KB With Remove-WindowsPackage

Remove installed Windows packages whose package identity contains a given KB number by using the DISM PowerShell cmdlets.

Source article: TBD

## Script

| Script | Purpose |
| --- | --- |
| `Remove-KBPackage.ps1` | Finds installed Windows packages matching a KB and removes them with `Remove-WindowsPackage`. |

## Usage

List matching packages:

```powershell
Get-WindowsPackage -Online |
  Where-Object { $_.PackageName -match "KB5032189" } |
  Select-Object PackageName, State, InstallTime
```

Remove matching packages:

```powershell
.\Remove-KBPackage.ps1 -KB KB4589210 -NoRestart
```

You can also pass the KB number without the `KB` prefix:

```powershell
.\Remove-KBPackage.ps1 -KB 4589210 -NoRestart
```

## Notes

- Run from an elevated PowerShell session.
- `Remove-WindowsPackage` removes installed package identities, not `.msu` files directly.
- Servicing Stack Updates usually cannot be uninstalled.
- If `DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase` was run, existing update packages can no longer be uninstalled.
