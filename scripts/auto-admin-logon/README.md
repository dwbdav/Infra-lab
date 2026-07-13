# Auto Admin Logon

PowerShell example for enabling Windows automatic logon through the `Winlogon` registry keys.

Source article: [Setting Up Automatic Login in Windows 10 with Windows Master Images](https://blog.infra-lab.fr/2023/07/activate-autologon-with-windows-10/)

## File

| File | Purpose |
| --- | --- |
| `Enable.ps1` | Enables `AutoAdminLogon`, sets the default user, domain and password values, and forces automatic logon. |

## Notes

- The script contains placeholder values: `Compte`, `Password`, and `Domaine.local`.
- Replace those values before use in a lab or deployment workflow.
- Avoid storing production credentials in scripts or Git repositories.

