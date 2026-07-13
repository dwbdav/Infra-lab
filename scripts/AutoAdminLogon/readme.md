# 🔓 Enable Automatic Logon (Windows)

PowerShell script that configures **Windows automatic logon** by writing the
`Winlogon` registry values, so the machine signs in with a predefined account at boot.

## 🔧 What it does
Sets the following keys under
`HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`:

- `AutoAdminLogon = 1` — enable auto logon
- `ForceAutoLogon = 1` — re-apply auto logon after each sign-out
- `DefaultUsername`, `DefaultDomainName`, `DefaultPassword` — the credentials used

## ✅ Prerequisites
- Run **PowerShell as Administrator**.
- Edit the variables at the top of `Enable.ps1` before running:
  ```powershell
  $DefaultUsername = "Compte"
  $DefaultPassword = "Password"
  $DefaultDomaine  = "Domaine.local"
  ```

## 🚀 Usage
```powershell
powershell -ExecutionPolicy Bypass -File .\Enable.ps1
```

## ⚠️ Notes
- The password is stored **in clear text** in the registry (`DefaultPassword`).
  Use only on lab/kiosk machines, never for privileged or domain admin accounts.
- For a local account, set `$DefaultDomaine` to the computer name (or `.`).

🔗 More details: **[Activate Autologon with Windows 10](https://blog.infra-lab.fr/2023/07/activate-autologon-with-windows-10/)**
