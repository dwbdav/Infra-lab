# Install MSU From Web Download

Download a Microsoft Update Catalog `.msu` file, run basic prerequisites, install it silently with `wusa.exe`, and return the native installer exit code.

Source article: [Tanium Patch Troubleshooting and Deployment Checks](https://blog.infra-lab.fr/2025/07/tanium-patch/)

## Scripts

| Script | Purpose |
| --- | --- |
| `Install-MSU-Direct.ps1` | Downloads one direct Microsoft Update Catalog MSU URL and installs it with `wusa.exe /quiet /norestart`. |
| `installmsu.ps1` | Original direct download variant. |
| `installmsuv2.ps1` | Variant that reads patch metadata from a web JSON endpoint and posts status messages to a web endpoint. |
| `installmsuv3.ps1` | Variant that combines web status reporting with `PSWindowsUpdate` checks. |

## Checks

- Pending reboot: exits `101`
- Free space on `C:` lower than 5 GB: exits `103`
- Download failure: exits `104`
- `wusa.exe` return code is returned as the script exit code
- The web variants add their own status codes and remote reporting logic.

## Usage

Edit these variables at the top of `Install-MSU-Direct.ps1`:

```powershell
$MSUFile = "windows10.0-kb5060531-x64.msu"
$MSUUrl = "https://catalog.s.download.windowsupdate.com/..."
```

Run from an elevated PowerShell session:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-MSU-Direct.ps1
```

## Notes

- The direct MSU variants download files to `C:\Windows\Temp`.
- Logs are written to `C:\Windows\Temp\MSU_Install.log` when using the normalized script.
- The web variants contain the original lab endpoint URLs and should be adapted before reuse outside that lab.
