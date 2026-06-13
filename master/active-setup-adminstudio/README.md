# Active Setup AdminStudio Template

Windows registry template for using Active Setup with an AdminStudio/MSI deployment.

Source article: [Windows Taskbar Customization with Windows Master Images](https://blog.wuibaille.fr/2023/12/windows-taskbar-customization/)

## File

| File | Purpose |
| --- | --- |
| `ActiveSetup.reg` | Template using `[ProductCode]` and `[ProductName]` placeholders with an MSI repair command in `StubPath`. |

## Notes

- Replace `[ProductCode]` and `[ProductName]` with the MSI package values.
- The template runs `msiexec /fu [ProductCode]` once per user through Active Setup.

