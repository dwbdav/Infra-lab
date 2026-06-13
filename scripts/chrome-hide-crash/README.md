# Chrome Hide Crash Notification

PowerShell script that updates the Chrome user `Preferences` file to clear the crashed session state.

Source article: [Deploy Applications with Quest SMA Managed Installations](https://blog.wuibaille.fr/2023/04/sma-distributions-des-applications/)

## File

| File | Purpose |
| --- | --- |
| `HideCrash.ps1` | Replaces Chrome `exit_type` value from `Crashed` to `Normal` in the current user's profile. |

## Notes

- Run the script as the target logged-on user.
- Chrome should be closed before modifying the preferences file.

