# 🔐 TPM + BitLocker Automation (Dell/HP)

PowerShell script that prepares a machine and **enables BitLocker** end-to-end:
it turns on the TPM in BIOS if needed, validates the prerequisites, encrypts the
system drive, and backs up the recovery key to Active Directory.

## 🔧 What it does
- **Enables TPM** in BIOS when not ready:
  - **Dell** via the bundled `DellBIOSProvider` module (optional `-BiosPassword`).
  - **HP** via `root/hp/instrumentedBIOS` (sets *TPM Device* to **Enable**).
- Validates **UEFI** firmware and that **no reboot is pending** (Windows Update/CBS/etc.).
- Encrypts **C:** with BitLocker (**TPM protector**, XtsAes128, recovery password).
- Optionally encrypts **D:** once C: is fully encrypted (**auto-unlock** on D:).
- **Backs up** the C: BitLocker recovery key to **Active Directory**.

## 📌 Requirements
- Run **PowerShell as Administrator**.
- **UEFI** firmware, a **TPM** chip, and **no pending reboot**.
- Domain-joined machine with AD permission to escrow the recovery key.
- The `Modules\DellBIOSProvider` folder is shipped alongside the script (for Dell).

## 🚀 Usage
```powershell
powershell -ExecutionPolicy Bypass -File .\EnableBitlocker.ps1
```

## ⚠️ Notes
- Exits with code **20200** if the TPM cannot be made ready.
- If the BIOS is password-protected on Dell, adapt the `Enable-TPM_Dell` call to pass
  the password.
- Test on a lab machine first — this encrypts the system drive.
