# Report Failed WSUS Computers

Generate a report of WSUS clients currently in failed update status and display the failed updates for the top recurring computers.

Source article: TBD

## Script

| Script | Purpose |
| --- | --- |
| `Display.ps1` | Exports failed WSUS computers to CSV, merges local CSV history, and displays the top recurring failed computers with failed update titles. |

## Requirements

- Run on the WSUS server.
- Use an elevated 64-bit Windows PowerShell session.
- WSUS PowerShell cmdlets available, including `Get-WsusComputer`.
- WSUS Administration assembly available:
  `C:\Program Files\Update Services\Tools\Microsoft.UpdateServices.Administration.dll`

## Usage

```powershell
.\Display.ps1
```

## Output

- Creates a dated CSV file in the script directory:
  `WSUSFailedComputer_MMddyy.csv`
- Displays the top recurring failed computers in the console.
- Displays failed update titles for matching computers.

## Notes

- The script reads all `*.csv` files in its own folder to build a simple local history.
- Clean old CSV files if you want to reset the recurring failure count.
