# Windows 11 OEM Activation

PowerShell script that reads the OEM product key embedded in BIOS and activates Windows.

Source article: [Windows 11 OEM Activation](https://blog.wuibaille.fr/2023/05/activation-oem-windows-11/)

## File

| File | Purpose |
| --- | --- |
| `OEMActivation.ps1` | Reads `OA3xOriginalProductKey`, installs it with `slmgr.vbs -ipk`, then activates with `slmgr.vbs -ato`. |

## Notes

- Run as administrator.
- Requires a BIOS-embedded OEM key and normal Windows activation connectivity.

