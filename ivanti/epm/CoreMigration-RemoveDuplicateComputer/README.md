# removeduplicate.ps1 — Remove Duplicate Devices

Delete duplicate computer objects left on an **old Core** after migrating to a **new Core**.  
The script connects to both Cores via the legacy SOAP endpoint (`MBSDKService/MsgSDK.asmx`), compares by `DeviceName`, and deletes the matching device from the old Core (skips names starting with `newcore`, and ignores `GUID = "Unassigned"`).

## Requirements
- An account with rights to list devices and delete computers.
- Windows PowerShell 5.1.

## Configure
Edit the two endpoints in the script:
```powershell
$ldWSold = New-WebServiceProxy -Uri http://oldcore.example.com/MBSDKService/MsgSDK.asmx  -Credential $mycreds
$ldWSNew = New-WebServiceProxy -Uri https://newcore.example.com/MBSDKService/MsgSDK.asmx -Credential $mycreds
```

## Run
Edit the two endpoints in the script:
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\removeduplicate.ps1
```
