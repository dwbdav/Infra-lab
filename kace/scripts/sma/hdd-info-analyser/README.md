# HDD Info Analyser with Quest SMA

Source article: https://blog.wuibaille.fr/2023/04/sma-utilisation-des-scripts/

## Purpose

Run `smartctl.exe` from Quest SMA to collect basic disk information and write the result to a local inventory file.

## Files

- `ScanHDD.bat` : launches `smartctl.exe` and writes the output to `C:\Windows\HDD-Info-Analyser.txt`.

## Dependency

The original source folder included `smartctl.exe` from smartmontools. It is not committed here because this public repository should avoid redistributing third-party binaries.

Download smartmontools if needed:

https://www.smartmontools.org/

Place `smartctl.exe` in the same folder as `ScanHDD.bat` before deploying the files as Quest SMA dependencies.

## Quest SMA inventory rule

```text
ShellCommandTextReturn(c:\windows\system32\cmd.exe /c type C:\Windows\HDD-Info-Analyser.txt)
```

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or UNC path detected.
- `smartctl.exe` was identified as a smartmontools binary and intentionally excluded.
