# MDT OOBE and OEM Activation Applications

Source article: https://blog.infra-lab.fr/2023/04/deploiement-de-windows-11-en-oobe-avec-mdt/

## Purpose

Two MDT application examples for Windows deployment:

- OOBE mode: relaunches Windows first-run experience with Sysprep.
- OEM activation: reads the embedded OEM product key from firmware and activates Windows.

## Files

- `Win10OOBE/install.cmd` : runs `sysprep.exe /oobe /quit`.
- `ActivateW10OEM/install.cmd` : launches the PowerShell activation script.
- `ActivateW10OEM/ActivationW10OEM.ps1` : reads `OA3xOriginalProductKey`, installs the key with `slmgr.vbs`, activates Windows and checks whether the license description contains `OEM`.

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or UNC path detected.
- No product key is hardcoded; the script reads the OEM key from the target machine firmware.
