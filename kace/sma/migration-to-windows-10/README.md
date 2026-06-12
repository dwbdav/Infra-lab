# Migration to Windows 10 with Quest SMA

Source article: to be linked when the matching blog post is published or identified.

## Purpose

Example Quest SMA workflow files for launching a Windows 10 in-place upgrade from a local ISO package.

## Layout

- `Rapport/Rapport.txt` : SQL report example to list OS build and user information.
- `ToISO/install.bat` : launches Windows Setup with upgrade parameters.
- `ToISO/setupcomplete.cmd` : post-upgrade cleanup hook.
- `ToTask/Install/StartInstall.bat` : extracts `ISOW10.zip` with 7-Zip and starts the upgrade.
- `ToTask/Install/7z.exe` and `ToTask/Install/7z.dll` : 7-Zip command-line binaries required by `StartInstall.bat`.
- `ToTask/Cleanup/Cleanup.bat` : cleanup task for temporary files, browser caches and Windows cleanup categories.

## Values to adapt

- `c:\ISOw10\ISOW10.zip` must exist before `StartInstall.bat` runs.
- `c:\Drivers` is used as the driver folder during setup.
- `W269N-WFGWX-YVC9B-4J6C9-T83GX` is a Microsoft generic KMS client setup key for Windows Pro.
- `Cleanup.bat` deletes temporary files and browser caches for local user profiles.

## Warnings

- Test this workflow in a lab before production use.
- `Cleanup.bat` removes files under temp and cache locations.
- The Windows setup command uses `/compat IgnoreWarning`; review compatibility handling before deployment.
- The script expects the Windows setup files to be present after extracting `ISOW10.zip`.

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or UNC path detected.
- 7-Zip binaries are included because they are required by the original Quest SMA task package.
- The product key is a documented Microsoft generic KMS client setup key.
