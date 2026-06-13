# Run As Administrator

PowerShell note for forcing a script to run from an elevated session.

Blog category: [PowerShell Administration Scripts](https://blog.wuibaille.fr/category/administration/scripts-administration/)

## Snippet

Add this line at the beginning of a PowerShell script:

```powershell
#Requires -RunAsAdministrator
```

PowerShell stops execution if the script is not launched with administrator privileges.

