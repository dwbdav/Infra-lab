# Deploy Chrome Enterprise

PowerShell installer for Google Chrome Enterprise MSI.

Source article: [Deploy Applications with Quest SMA Managed Installations](https://blog.wuibaille.fr/2023/04/sma-distributions-des-applications/)

## File

| File | Purpose |
| --- | --- |
| `DownloadInstall.ps1` | Detects OS architecture, downloads the matching Chrome Enterprise MSI, and installs it silently. |

## Download Strategy

The script tries these methods in order:

1. `curl.exe`
2. BITS
3. `Invoke-WebRequest`

## Notes

- Official Google Chrome Enterprise MSI URLs are used.
- Proxy lines are included as comments and must be adapted if needed.
- The installer runs `msiexec.exe` with `/qn /norestart`.

