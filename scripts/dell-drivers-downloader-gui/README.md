# Dell Drivers Downloader GUI

PowerShell WPF GUI for selecting and downloading Dell driver packs from the Dell DriverPackCatalog.

Source article: [Driver Installation Tools with BIOS and Driver Management](https://blog.infra-lab.fr/2023/05/differentes-methodes-dinstallation-des-drivers/)

## Files

| File | Purpose |
| --- | --- |
| `DownloadDriversGUI.ps1` | GUI and download logic. |
| `DownloadDriversGUI.xml` | Local configuration for the GUI. |
| `DriverPackCatalog.cab` | Dell driver pack catalog archive. |
| `DriverPackCatalog.xml` | Extracted Dell driver pack catalog. |
| `readme.png` | Screenshot from the source documentation. |

## Notes

- Run PowerShell in STA mode.
- The script expects 7-Zip at `C:\Program Files\7-Zip\7z.exe`.

