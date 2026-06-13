# Provisioning High Performance Power Plan

Batch helper used during Ivanti EPM provisioning to switch Windows to the built-in High performance power plan.

## Files

| File | Description |
| --- | --- |
| `Performance.cmd` | Activates the Windows High performance power plan. |

## Command

The script runs:

```cmd
powercfg.exe -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
```

`8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c` is the standard GUID for the Windows High performance power scheme.

## Usage

Add `Performance.cmd` as a System Configuration action in an Ivanti EPM provisioning template.

## Notes

- Use this before heavy provisioning actions such as driver injection, software installation, or image deployment steps.
- The setting can be changed later by policy or by another power plan command.
