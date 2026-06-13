# Provisioning HII Driver Injection

Driver injection helpers for Ivanti EPM provisioning. The scripts detect the computer vendor and model, locate the matching driver folder, and inject drivers into the offline Windows image.

Source article: [Provisionning - Alternative to Ivanti HII](https://blog.wuibaille.fr/2023/04/epm-hii-ps1-alternative-au-hii-ivanti/)

## Files

| File | Description |
| --- | --- |
| `Hii.ps1` | PowerShell version. Detects model and injects drivers from a source path passed with `-path`. |
| `Hii.exe` | Compiled executable version of `Hii.ps1`, useful in WinPE environments. |
| `HII.bat` | Legacy batch implementation with model normalization and driver injection logic. |

## PowerShell Usage

Run the script with the root folder that contains model-specific driver folders:

```powershell
.\Hii.ps1 -path "Y:\Drivers\PnPDrivers"
```

Expected driver folder format:

```text
<DriverRoot>\<Vendor>_<Model>
```

Example:

```text
Y:\Drivers\PnPDrivers\HP_840G6
```

## Batch Usage

Edit `DriverRoot` in `HII.bat` if your driver source is not mapped to `Y:\Drivers\PnPDrivers`:

```cmd
SET DriverRoot=y:\Drivers\PnPDrivers
```

The batch version expects this structure:

```text
<DriverRoot>\<Vendor>_<Model>\<OS>\<Architecture>
```

Example:

```text
Y:\Drivers\PnPDrivers\HP_840G6\Win10\X64
```

## Notes

- `Hii.exe` is included so the workflow can run in WinPE without relying on PowerShell availability.
- Review and adapt model normalization rules for your hardware catalog.
- The source paths in `HII.bat` are intentionally generic and should be adapted to your provisioning share.
