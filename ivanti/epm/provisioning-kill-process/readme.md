# Kill Ivanti Provisioning Process

PowerShell helper used to repeatedly stop the Ivanti EPM provisioning process `Ldprovision`.

## Files

| File | Description |
| --- | --- |
| `killldprovisionning.ps1` | Stops `Ldprovision` in a loop for troubleshooting or recovery scenarios. |

## Usage

Run from an elevated PowerShell prompt:

```powershell
.\killldprovisionning.ps1
```

## Behavior

The script loops up to 1000 times and runs:

```powershell
Stop-Process -Name "Ldprovision" -Force -ErrorAction SilentlyContinue
```

It waits 3 seconds between each attempt.

## Notes

- Use only when a provisioning task is stuck or must be interrupted.
- Running this during an active deployment can stop the provisioning workflow.
