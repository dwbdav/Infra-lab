# Windows Cleanup

Batch script for Windows component cleanup and Disk Cleanup automation.

Blog category: [Windows Master Images](https://blog.wuibaille.fr/category/administration/master/)

## File

| File | Purpose |
| --- | --- |
| `cleanup.cmd` | Runs DISM component cleanup, deletes Windows temp files, configures CleanMgr flags and runs Disk Cleanup. |

## Notes

- Run as administrator.
- This removes rollback/cache data such as Windows Update cleanup and previous installation files.

