# 🌍 IP Range Calculator

## 🔧 What it does
- Uses **Gateway** and **Subnet Mask** to calculate the **first (Host Min)** and **last (Host Max)** usable IP addresses in the range.  
- Displays results directly in the console.

## ✅ Prerequisites
- Function `Get-IPRange` must be defined in the same script or imported.  
- Provide valid IPv4 **gateway** and **subnet mask**.  

```powershell
$gateway = "192.168.1.1"
$subnetMask = "255.255.255.0"
$startAddress, $endAddress = Get-IPRange -gateway $gateway -subnetMask $subnetMask
```