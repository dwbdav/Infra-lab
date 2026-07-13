# Pre-Installation Diskpart Tasks with Quest SDA

Source article: https://blog.infra-lab.fr/2023/04/sda-taches-de-pre-installation-diskpart/

## Purpose

Prepare disk 0 during a Quest SDA pre-installation task, using BIOS or UEFI partitioning depending on the detected firmware mode.

## Warning

These scripts run `diskpart clean` on disk 0. They erase the target disk and must only be used in a controlled deployment or imaging workflow.

## Files

- `Partition.bat` : detects the WinPE firmware type and runs the BIOS or UEFI Diskpart script.
- `Disk.au3` : AutoIt source that detects firmware type and launches the matching Diskpart script.
- `Disk_x64.exe` : compiled 64-bit executable for the AutoIt workflow.
- `Disk_x86.exe` : compiled 32-bit executable for the AutoIt workflow.
- `BIOS.txt` : Diskpart script for BIOS/MBR partitioning.
- `UEFI.txt` : Diskpart script for UEFI/GPT partitioning.

## Executable hashes

```text
Disk_x64.exe SHA256: 4736A55DEC682277250E7F4B3A6B9E85E574B0085903E0A2BD700A61F69A2C00
Disk_x86.exe SHA256: E00097AA5542923EB9B54C3EE348C5D310E77408A81B5917D6C641FB7517DFD2
```

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or UNC path detected.
- The compiled AutoIt executables are included with SHA256 hashes.
