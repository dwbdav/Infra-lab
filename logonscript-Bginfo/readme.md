# 🖼️ BGInfo One‑Liner

## 🔧 What it does
Runs **BGInfo** with your `.bgi` layout **silently**, auto‑accepts EULA, and applies immediately.

```cmd
"%~dp0Bginfo.exe" "%~dp0Labo.bgi" /accepteula /silent /timer 0
```

## ✅ Prerequisites
- `Bginfo.exe` and your `.bgi` file must be in the **same folder**.  
- Run as part of a **GPO logon script** or manually.

🔗 Help & setup guide: **[Deploying BGInfo via GPO](https://blog.wuibaille.fr/2024/05/deploying-bginfo-via-gpo/)**