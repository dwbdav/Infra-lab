# Active Setup Template for AdminStudio

A **Windows Registry (.reg) template** to configure **Active Setup** for AdminStudio
(MSI) deployments. Active Setup runs a per-user action **once at first logon**, which is
ideal for repairing/reinstalling per-user MSI components that machine-wide installs miss.

## 📂 Files
- `ActiveSetup.reg` — the registry template to customize and import.

## 🔧 What it does
Creates a key under
`HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\[ProductCode]` with:

- `IsInstalled = 1` and a `Version` stamp (bump it to re-trigger on existing users)
- `StubPath = "msiexec /fu [ProductCode]"` — the per-user repair command run at logon

## 🚀 Usage
1. Edit `ActiveSetup.reg` and replace the placeholders:
   - `[ProductCode]` → your MSI product GUID
   - `[ProductName]` → a display name / component ID
   - `Version` → increment to force the action to re-run for users who already logged on
2. Import it (typically as part of your package's machine-wide install):
   ```cmd
   reg import ActiveSetup.reg
   ```

## ⚠️ Notes
- Runs in the **user** context at first logon, after the machine-wide install.
- Increasing `Version` is what makes Active Setup re-run for users who already have the
  current value — keep it consistent with your package versioning.
