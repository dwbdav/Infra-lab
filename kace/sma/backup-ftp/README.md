# Backup Quest SMA Files with FTP

Source article: https://blog.infra-lab.fr/2023/04/sma-installation-de-la-solution/

## Purpose

Download Quest SMA backup archives from the appliance FTP backup service with WinSCP command-line mode.

## Files

- `lance.bat` : launches WinSCP in console mode with `script.ftp`.
- `script.ftp` : WinSCP command file that connects to the Quest SMA FTP backup service and downloads backup archives.
- `WinSCP.com` : WinSCP console executable.
- `WinSCP.exe` : WinSCP executable required by `WinSCP.com`.

## Values to adapt

In `script.ftp`:

- `K1000` is the Quest SMA appliance hostname used in the article example.
- `kbftp` is the Quest SMA FTP backup account.
- `getbxf` is the default FTP backup password documented in the article example.
- `C:\Users\Administrateur\Desktop\backup` is the local backup destination path.

Update these values before using the script in another environment.

## Publication check

- No GitHub token detected.
- No API key or bearer token pattern detected.
- No email, internal URL, private IP or UNC path detected.
- The `kbftp/getbxf` credential is kept because it is the documented Quest SMA FTP backup example from the source article.
- `WinSCP.ini` was intentionally excluded because it contains local application state and workstation-specific paths.
