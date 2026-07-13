# Hyper-V Backup VM

PowerShell script that exports Hyper-V virtual machines matching `*Backup_*` and copies the export to a backup share.

Blog category: [Infra](https://blog.infra-lab.fr/category/administration/infra-administration/)

## File

| File | Purpose |
| --- | --- |
| `exportbackupVM.ps1` | Exports matching VMs to `D:\export`, copies them to a backup path, then cleans the export folder. |

## Notes

- The source script uses the lab path `\\192.168.0.3\backup\VM`.
- Run from a Hyper-V host with the Hyper-V PowerShell module available.
- Review the cleanup steps before running in production.

