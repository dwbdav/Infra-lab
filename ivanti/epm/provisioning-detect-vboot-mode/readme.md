# Detect VBoot Mode

PowerShell helper used during Ivanti EPM provisioning to detect whether a task successfully ran in VBoot mode.

## Files

| File | Description |
| --- | --- |
| `DetectVbootMode.ps1` | Reads the Ivanti provisioning log and creates a flag file when VBoot is detected. |

## Behavior

The script:

1. Reads `C:\ldprovisioning\ProvisionGUI.exe.log`.
2. Searches for a line containing both `SUCCESS` and `Vboot`.
3. Creates `C:\exploit\vbooton.flg` with the value `vboot` when a match is found.

## Usage

Run during an Ivanti provisioning task:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\DetectVbootMode.ps1
```

The flag file can then be used by later provisioning steps to trigger conditional logic.

## Notes

- Make sure `C:\exploit` exists before running the script, or adapt the output path.
- The script expects the standard Ivanti provisioning log path.
