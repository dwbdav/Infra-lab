# Windows MUI Build

PowerShell scripts for building Windows 11 multilingual installation media.

Blog category: [Windows Master Images](https://blog.infra-lab.fr/category/administration/master/)

## Files

| File | Purpose |
| --- | --- |
| `BuildMUI.ps1` | GUI-oriented MUI build workflow. |
| `BuildWindowsMui_W11_PRO_22H2_MuiOfficiel.ps1` | Windows 11 Pro 22H2 MUI build script with official MUI packages. |
| `BuildWindowsMui_W11_PRO_22H2_MultiIndex.ps1` | Multi-index Windows 11 Pro 22H2 MUI build script. |

## Notes

- Source network paths were replaced with generic `\\fileserver\...` lab paths.
- Requires Windows ADK and matching Windows source media.

