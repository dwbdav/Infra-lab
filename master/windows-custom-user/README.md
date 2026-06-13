# Windows Custom User

Per-user Windows customization through Active Setup.

Blog category: [Windows Master Images](https://blog.wuibaille.fr/category/administration/master/)

## Files

| File | Purpose |
| --- | --- |
| `ActiveSetup.reg` | Registers the per-user customization command. |
| `CustWin.cmd` | Applies taskbar, Start menu and Appx cleanup settings under the user context. |
| `install.cmd` | Copies `CustWin.cmd` to `C:\Windows` and imports the Active Setup registry file. |

