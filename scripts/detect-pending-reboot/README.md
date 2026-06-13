# Detect Pending Reboot

PowerShell script that checks common Windows pending reboot indicators and reacts depending on whether a user session is active.

Source article: [Deploy - Force Reboot after Installation with Ivanti EPM](https://blog.wuibaille.fr/2023/05/gestion-des-demandes-de-reboot/)

## File

| File | Purpose |
| --- | --- |
| `GetNeedReboot.ps1` | Detects pending reboot registry flags, checks for a logged-on user session, sends a message, or restarts the computer. |

## Checks

- Windows Update `RebootRequired`
- Component-Based Servicing `RebootPending`
- Pending file rename operations
- MSI `UpdateExeVolatile`

## Notes

- Run as administrator.
- Uses `msg.exe` to notify the logged-on user.
- If no user session is detected and a reboot is pending, the script calls `Restart-Computer -Force`.

