# Chrome Enterprise MSI — Fast Auto-Arch Installer (PowerShell)

Downloads and silently installs **Google Chrome Enterprise MSI** with the **correct architecture**  
(**x64 on 64-bit OS, x86 on 32-bit OS**).  
Fast, resilient download pipeline: **curl.exe → BITS → Invoke-WebRequest** with **retries** and **timeouts**.  
**No version checks** (handled elsewhere by design).

> Official Google endpoints always deliver the **latest available** version.

## Features
- Auto-detects OS arch (x64/x86) and picks the proper **Enterprise MSI**.
- Download strategy with fallbacks: **curl.exe** (fast) → **BITS** (robust) → **IWR**.
- **Retries**, **timeouts**, and basic file sanity check.
- **Silent install** (`/qn /norestart`).
- No uninstall / no version comparison (deliberate).

