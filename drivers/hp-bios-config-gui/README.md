# HP BIOS Config GUI

PowerShell and WPF tool to audit and apply selected HP BIOS settings.

Blog category: [Bios & Drivers](https://blog.wuibaille.fr/category/administration/drivers/)

## File

| File | Purpose |
| --- | --- |
| `HpBiosConfigGui.ps1` | Displays configured HP BIOS settings and applies expected values with `SetBIOSSetting`. |

## Usage

```powershell
powershell.exe -sta -ExecutionPolicy Bypass -File .\HpBiosConfigGui.ps1
```

## Notes

- Requires HP WMI BIOS classes under `root/hp/instrumentedBIOS`.
- Edit the expected values table in the script to match your BIOS policy.

