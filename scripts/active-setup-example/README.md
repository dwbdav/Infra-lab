# Active Setup Example

Minimal Active Setup sample that registers a per-user action and runs it when a user logs on.

Source article: [Windows Taskbar Customization with Windows Master Images](https://blog.infra-lab.fr/2023/12/windows-taskbar-customization/)

## Files

| File | Purpose |
| --- | --- |
| `ActiveSetup.reg` | Registers the Active Setup component under `HKLM`. |
| `install.bat` | Copies the payload to `C:\Windows` and imports the registry file. |
| `ScreenSaver.bat` | Example per-user payload that writes screensaver settings under `HKCU`. |

## Usage

Run `install.bat` as administrator during image preparation or deployment:

```cmd
install.bat
```

At next user logon, Windows runs the configured `StubPath` once for that user.

