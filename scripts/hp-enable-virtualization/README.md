# HP Enable Virtualization

PowerShell script that enables HP BIOS virtualization settings through `root/hp/instrumentedBIOS`.

Blog category: [Bios & Drivers](https://blog.wuibaille.fr/category/administration/drivers/)

## File

| File | Purpose |
| --- | --- |
| `Enable-Virtualization.ps1` | Enables `Virtualization Technology (VTx)` and `Virtualization Technology for Directed I/O (VTd)`. |

## Notes

- Run as administrator on supported HP hardware.
- A reboot may be required before the BIOS changes take effect.
- Password-protected BIOS configurations may require additional handling.

