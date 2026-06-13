# 🔑 Windows 7 OEM (SLP) Activation Certificates

This folder gathers the **OEM SLP activation certificates** (`.xrm-ms`) used to
offline-activate **Windows 7** on genuine OEM hardware that carries the matching
**BIOS SLIC 2.1 marker**.

## 📂 Files
- `DELL_V2.1_Cert.xrm-ms` — Dell OEM certificate
- `HPQOEM_V2.1_Cert.xrm-ms` — HP OEM certificate
- `LENOVO_V2.1_Cert.xrm-ms` — Lenovo OEM certificate

## 🔧 How OEM SLP activation works
On an OEM machine, Windows 7 activates **offline** when three things match: the
BIOS **SLIC table**, the OEM **certificate** installed below, and an OEM **SLP product
key** for that edition. No connection to Microsoft is required.

## 🚀 Usage
From an elevated command prompt, pick the certificate for your hardware vendor:

```cmd
slmgr.vbs -ilc "DELL_V2.1_Cert.xrm-ms"
slmgr.vbs -ipk <OEM-SLP-product-key-for-your-edition>
slmgr.vbs -ato
slmgr.vbs -dli      :: check status
```

## ⚠️ Notes
- Works **only** on genuine OEM systems whose BIOS contains a valid **SLIC 2.1** marker
  for the matching vendor; it does not bypass licensing on other hardware.
- Use the SLP key that corresponds to the installed **edition** (Pro, Enterprise, …).
- Windows 7 is **end-of-life**; this is provided for legacy/lab reinstall scenarios only.
