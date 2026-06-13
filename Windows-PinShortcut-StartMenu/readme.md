# 📌 Pin Firefox to Start Menu (VBScript)

## 🔧 What it does
- Removes any existing **pinned Start Menu** shortcut for Firefox from the current user.
- Uses Windows Shell verbs to **pin “Mozilla Firefox.lnk”** to the **Start Menu** (All Users Start Menu folder).

## ✅ Prerequisites
- Firefox installed and a shortcut named **`Mozilla Firefox.lnk`** present in  
  `C:\ProgramData\Microsoft\Windows\Start Menu`
- Run under the **target user profile** (affects that user’s Start pins).
- Works on **French Windows** (relies on shell verb text e.g., “Épingler au menu Démarrer”).  
  For other languages, adjust the verb matching in the script.
