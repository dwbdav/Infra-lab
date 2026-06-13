# HP BIOS Config GUI

A minimal **PowerShell + WPF** tool to **audit and enforce BIOS settings** on HP devices via `root/hp/instrumentedBIOS`.

## ✨ What it does
- Reads current BIOS values (`hp_biosEnumeration`)
- Compares to an **expected policy** (color‑coded: green = OK, red = mismatch)
- **Configure** button applies changes with `hp_biossettinginterface.SetBIOSSetting`
- Live refresh + error summary

## 📌 Requirements
- HP device exposing `root/hp/instrumentedBIOS`
- Windows + PowerShell (run as Administrator, STA)
- .NET Framework (WPF)

## 🚀 Usage
1. (Optional) Edit the `expectedValues` table in the script to match your policy.  
2. Run in an elevated, STA PowerShell:
   ```powershell
   powershell -sta -File .\HpBiosConfigGui.ps1
   ```
3. Review statuses → Configure to enforce → confirm results.