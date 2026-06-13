# 🖨️ Automated Printer Installation Script

## 🔧 What it does
This script automates the installation of a **network printer**:
- Detects if the system is **x86 or x64**.
- Creates a **TCP/IP printer port** with the provided IP address.
- Installs the correct **printer driver** (from `.INF` file).
- Installs the printer with the specified **friendly name**.

---

## ✅ Parameters to edit in the script
- `FichierINFx64` → Driver `.INF` file for **64-bit** systems.  
- `FichierINFx86` → Driver `.INF` file for **32-bit** systems.  
- `NomDrivers` → Exact driver name (copy/paste from inside the `.INF` file).  
- `AdresseIP` → Printer IP address.  
- `NomImprimante` → Friendly name displayed in **Printers & Scanners**.  

Example:
```batch
Set FichierINFx64=CNLB0FA64.INF
Set FichierINFx86=CNLB0F.INF
Set NomDrivers=Canon iR1133 UFRII LT
Set AdresseIP=192.168.0.112
Set NomImprimante=COPIEUR BE
```

## ⚠️ Notes

- The `.INF` driver files must be stored in:
  - `.\x64\` → for 64-bit  
  - `.\x86\` → for 32-bit  
- The driver name must **exactly match** the one inside the `.INF` file, otherwise installation will fail.  
- Requires **administrator rights**.  
- After installation, the script waits **10 seconds** before exiting.  
