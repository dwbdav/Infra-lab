# Manage WinPE For Ivanti EPM

Tools to customize Ivanti EPM WinPE boot images: back up and mount the WIM, edit `startnet.cmd`, update `corename.txt`, inject drivers, and generate ISO files.

Source article: [Provisionning - WinPE with Ivanti EPM](https://blog.wuibaille.fr/2023/04/epm-gestion-des-winpe/)

## Files

| File | Purpose |
| --- | --- |
| `ManageWinPE.ps1` | GUI helper to update `boot_x64.wim` or `boot.wim` from an EPM Core share. |
| `CreateISOx64.bat` | Creates an x64 WinPE ISO from the EPM Core WIM. |
| `CreateISOx86.bat` | Creates an x86 WinPE ISO from the EPM Core WIM. |
| `choice_x64.exe` | Copied into x64 WinPE as `choice.exe` for keyboard selection. |
| `choice_x86.exe` | Copied into x86 WinPE as `choice.exe` for keyboard selection. |
| `Drivers/x64/` | x64 WinPE drivers injected by `ManageWinPE.ps1`. |
| `Drivers/x86/` | x86 WinPE drivers injected by `ManageWinPE.ps1`. |

## Usage

Run the GUI:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\ManageWinPE.ps1
```

Create an ISO from an EPM Core WIM:

```bat
CreateISOx64.bat epm.example.local
CreateISOx86.bat epm.example.local
```

## Notes

- Run from an elevated deployment/admin workstation with the Windows ADK installed.
- The WinPE driver pack is included in `Drivers/x64` and `Drivers/x86`.
- The script backs up the original WIM before mounting and saving changes.
