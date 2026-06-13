# Windows Script Upgrade

Batch scripts for running a Windows in-place upgrade from local setup media.

Blog category: [Windows Master Images](https://blog.wuibaille.fr/category/administration/master/)

## Files

| File | Purpose |
| --- | --- |
| `upgrade_Cleanup.cmd` | Cleans temporary and deployment cache files before upgrade. |
| `upgrade_GetPendingReboot.cmd` | Checks common pending reboot indicators. |
| `upgrade_GetWim.cmd` | Displays `install.wim` indexes. |
| `upgrade_Install.cmd` | Runs Windows Setup with selected image index and local drivers. |
| `upgrade_setupcomplete.cmd` | Cleans migration folders after setup. |

## Notes

- The LDMS server value is a lab placeholder: `ldcore.monlab.lan`.
- Site-specific cache folders were renamed to generic `SiteA` and `SiteB` paths.

