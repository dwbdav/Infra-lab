# Dell Enable TPM

PowerShell script and DellBIOSProvider module copy for enabling TPM on Dell systems.

Source article: [TPM Activation with Windows Security Administration](https://blog.wuibaille.fr/2023/05/activation-des-puces-tpm/)

## Files

| File | Purpose |
| --- | --- |
| `ActiveTPM.ps1` | Enables `DellSmbios:\TpmSecurity\TpmSecurity`. |
| `install.cmd` | Copies DellBIOSProvider to the PowerShell module path and runs `ActiveTPM.ps1`. |
| `Modules/DellBIOSProvider` | Dell BIOS PowerShell provider included from the source folder. |

## Notes

- Run as administrator on supported Dell hardware.
- The script accepts an optional BIOS password parameter, but no real BIOS password is stored here.
- Review DellBIOSProvider sample scripts before reusing them in production.

