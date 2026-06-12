# Install MSU From Direct Download

Download a Microsoft Update Catalog `.msu` file, run basic prerequisites, install it silently with `wusa.exe`, and return the native installer exit code.

Source article: [Tanium Patch Troubleshooting and Deployment Checks](https://blog.wuibaille.fr/2025/07/tanium-patch/)

## Script

| Script | Purpose |
| --- | --- |
| `Install-MSU-Direct.ps1` | Downloads one direct Microsoft Update Catalog MSU URL and installs it with `wusa.exe /quiet /norestart`. |

## Checks

- Pending reboot: exits `101`
- Free space on `C:` lower than 5 GB: exits `103`
- Download failure: exits `104`
- `wusa.exe` return code is returned as the script exit code

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

- The MSU is downloaded to `C:\Windows\Temp`.
- Logs are written to `C:\Windows\Temp\MSU_Install.log`.
- The source folder also contained lab variants using a personal webservice endpoint; those variants are intentionally not published here.
