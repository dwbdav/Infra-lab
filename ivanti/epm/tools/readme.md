# Ivanti EPM Tools

Collection of legacy Ivanti EPM and LANDESK helper tools used for provisioning, driver copy, preferred server mapping, and database repair workflows.

## Contents

| Path | Description |
| --- | --- |
| `CopyDrivers/CopyDrivers.au3` | AutoIt source for copying model-specific drivers during deployment. |
| `CopyDrivers_x64/CopyDrivers_x64.exe` | Compiled x64 CopyDrivers helper. |
| `DBrepair/EPM_DBRepair_2021.1.zip` | Ivanti EPM database repair package. |
| `DBrepair/UsingSnapshotInDbrepair_Rev1.pdf` | DBRepair snapshot documentation. |
| `Landesk_Autoit/` | Legacy AutoIt tools and compiled executables for LANDESK/Ivanti provisioning. |
| `Landesk_Autoit/HttpCopyV362/` | HttpCopy binaries used by some legacy workflows. |

## Landesk AutoIt Tools

| File | Description |
| --- | --- |
| `CopyDrivers.au3` / `CopyDrivers.exe` | Copy drivers based on model mapping. |
| `InjectMsd.au3` / `InjectMsd.exe` | Mass storage driver injection helper. |
| `prefmap.au3` / `prefmap.exe` | Preferred server share mapping helper. |
| `RunEnv.au3` / `RunEnv.exe` | Runtime environment helper. |
| `Preferred.bat` | Example command sequence for downloading and running `prefmap.exe`. |

## Notes

- These tools are legacy utilities. Test in a lab before using with production provisioning templates.
- `Preferred.bat` expects runtime variables such as `%coreIP%`, `%share%`, `%usr%`, and `%pwd%`.
- No production credentials are stored in this folder.
