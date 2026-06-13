# Provisioning End Restart and Shutdown

Batch helpers used at the end of an Ivanti EPM provisioning task to clean AutoLogon registry values and trigger a delayed restart or shutdown.

## Files

| File | Description |
| --- | --- |
| `restart.cmd` | Cleans AutoLogon values and starts a delayed restart. |
| `shutdown.cmd` | Cleans AutoLogon values and starts a delayed shutdown. |

## Behavior

Both scripts:

1. Use `Sysnative` when running from a 32-bit process on a 64-bit Windows system.
2. Skip AutoLogon cleanup when `C:\exploit\vbooton.flg` exists.
3. Remove these Winlogon values when cleanup is enabled:
   - `AutoAdminLogon`
   - `DefaultPassword`
   - `AutoLogonCount`
   - `ForceAutoLogon`
4. Disable the built-in local administrator account when a matching profile exists.

`restart.cmd` starts:

```cmd
shutdown.exe /r /t 60 /c "Final restart"
```

`shutdown.cmd` starts:

```cmd
shutdown.exe /s /t 60 /c "Shutdown"
```

## Usage

Add the required script as one of the final actions in an Ivanti EPM provisioning template:

```cmd
restart.cmd
```

or:

```cmd
shutdown.cmd
```

## Notes

- Use `restart.cmd` when the deployment workflow must boot once more before completion.
- Use `shutdown.cmd` when the machine should be powered off at the end of provisioning.
- The `C:\exploit\vbooton.flg` flag is intended to work with VBoot detection workflows.
