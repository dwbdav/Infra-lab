# 🖱️ HP EliteBook 850 G8 Touchpad Issue in WinPE

On **HP EliteBook 850 G8** (Intel Tiger Lake), the **touchpad may not work in WinPE**
because the **Intel Serial IO (LPSS) chipset drivers** are missing from the boot image.

This folder provides the matching driver pack **`P00XCK-B2M`** (Intel `iaLPSS2_*_TGL`:
GPIO2, I2C, SPI, UART2) to inject into your WinPE image.

> ℹ️ For the **850 G7** (Comet Lake), use the separate `WinPE-Drivers-Pb-TouchPad-850g7`
> folder instead — it ships the `P00VZ6-B2H` (`*_CNL`) drivers.

---

## 🔧 Fix: Inject Drivers into WinPE

1. Mount the WinPE image:
   ```powershell
   dism /mount-wim /wimfile:"\\ServeurLDMS\ldmain\landesk\vboot\boot_x64.wim" /index:1 /mountdir:c:\mount
   ```

2. Inject the Tiger Lake touchpad/serial-IO drivers (point to this folder):
   ```powershell
   Dism /Image:C:\mount /Add-Driver /Driver:"c:\WinPE-Drivers-Pb-TouchPad-850g8\P00XCK-B2M\src\driver\x64" /Recurse
   ```

3. Commit and unmount:
   ```powershell
   Dism /unmount-wim /mountdir:c:\mount /commit
   ```

## ⚠️ Notes
- Make sure the drivers match your exact HP model (**EliteBook 850 G8 / Tiger Lake**).
- Always back up your original `boot.wim` before modification.
