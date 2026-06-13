# Get Range IP

PowerShell function that calculates the first and last usable IPv4 host addresses from a gateway and subnet mask.

Blog category: [PowerShell Administration Scripts](https://blog.wuibaille.fr/category/administration/scripts-administration/)

## File

| File | Purpose |
| --- | --- |
| `GetRangeIP.ps1` | Defines `Get-IPRange`, returning host min and host max addresses. |

## Example

```powershell
$gateway = "192.168.1.1"
$subnetMask = "255.255.255.0"
$startAddress, $endAddress = Get-IPRange -gateway $gateway -subnetMask $subnetMask
```

