# Progress Bar

PowerShell `Write-Progress` snippet for displaying progress while processing a list of computers.

Blog category: [PowerShell Administration Scripts](https://blog.infra-lab.fr/category/administration/scripts-administration/)

## File

| File | Purpose |
| --- | --- |
| `Progressbar.ps1` | Shows progress based on the current item index and total item count. |

## Notes

- The source snippet expects `$OrdinateurClient` to contain the list of computers.
- Each item is expected to expose a `DISPLAYNAME` property.

