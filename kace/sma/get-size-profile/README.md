# Get User Profile Sizes with Quest SMA

Source article: https://blog.infra-lab.fr/2023/04/sma-utilisation-des-scripts/

## Purpose

Generate a local inventory file with user profile sizes so Quest SMA can collect the result through a custom inventory rule.

## Files

- `Getsize.vbs` : VBScript that writes profile size information to `C:\Windows\Temp\TailleProfils.log`.

## Dependency

The original source folder included `du.exe` from Sysinternals Du. It is not committed here because this public repository should avoid redistributing third-party binaries.

Download Sysinternals Du from Microsoft if needed:

https://learn.microsoft.com/sysinternals/downloads/du

Place `du.exe` in the same folder as `Getsize.vbs` before deploying the script as a Quest SMA dependency.

## Quest SMA inventory rule

```text
ShellCommandTextReturn(c:\windows\system32\cmd.exe /c type c:\Windows\temp\TailleProfils.log)
```

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or UNC path detected.
- `du.exe` was identified as a Sysinternals binary and intentionally excluded.
