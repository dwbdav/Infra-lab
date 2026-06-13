# Domain Join Helper (Batch)

Batch script to **configure DNS (optional)**, relax PowerShell execution policy for the session, and **join a Windows machine to an AD domain** using `netdom`.

## 📂 Files
- `Install.cmd` — main batch script  
- `SetDns.ps1` — optional DNS configuration helper (called by the batch)  
- `netdom.exe` (+ `en-US` / `fr-FR` resources) — bundled domain-join utility

## ⚙️ What it does
1. Executes `SetDns.ps1` (optional) to force lab DNS.  
2. Calls `netdom JOIN` to add the computer to the domain.  