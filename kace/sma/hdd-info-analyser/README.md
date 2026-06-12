# HDD Info Analyser with Quest SMA

Source article: https://blog.wuibaille.fr/2023/04/sma-utilisation-des-scripts/

## Purpose

Run `smartctl.exe` from Quest SMA to collect basic disk information and write the result to a local inventory file.

## Files

- `ScanHDD.bat` : launches `smartctl.exe` and writes the output to `C:\Windows\HDD-Info-Analyser.txt`.

## Dependency

`smartctl.exe` from smartmontools is included in this folder for the Quest SMA dependency package.

Project site:

https://www.smartmontools.org/

Deploy `ScanHDD.bat` and `smartctl.exe` together as Quest SMA dependencies.

## Quest SMA inventory rule

```text
ShellCommandTextReturn(c:\windows\system32\cmd.exe /c type C:\Windows\HDD-Info-Analyser.txt)
```

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or UNC path detected.
- `smartctl.exe` was identified as a smartmontools binary and intentionally included.
