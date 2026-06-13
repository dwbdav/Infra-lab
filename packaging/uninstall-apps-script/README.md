# Uninstall Apps Script

PowerShell function for removing installed applications by matching their Windows uninstall registry entries.

Blog category: [Application Packaging](https://blog.wuibaille.fr/category/administration/packaging/)

## File

| File | Purpose |
| --- | --- |
| `uninstallapp.ps1` | Defines `Uninstall`, detects MSI or EXE uninstall strings, and runs the silent uninstall command. |

## Notes

- Run PowerShell as administrator.
- `-AppName` performs a contains match on `DisplayName`.
- Review the sample uninstall calls at the bottom of the script before running.

