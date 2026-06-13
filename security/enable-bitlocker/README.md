# Enable BitLocker

PowerShell automation for enabling TPM and BitLocker on Windows devices.

Source article: [Configuring BitLocker with Windows Security Administration](https://blog.wuibaille.fr/2023/03/deployer-bitlocker-en-entreprise/)

## Files

| File | Purpose |
| --- | --- |
| `EnableBitlocker.ps1` | Enables TPM on Dell/HP if needed, validates UEFI and reboot state, then starts BitLocker on `C:` and optionally `D:`. |
| `Modules/DellBIOSProvider` | Dell BIOS PowerShell provider included from the source folder. |

## Notes

- Run as administrator.
- The script backs up the `C:` BitLocker recovery key to Active Directory.
- Review the behavior carefully before running on production devices.

