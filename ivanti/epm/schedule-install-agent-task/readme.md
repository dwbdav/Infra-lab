# Schedule Ivanti Agent Installation

PowerShell scripts used to reinstall or migrate an Ivanti EPM agent through a startup scheduled task.

## Files

| File | Description |
| --- | --- |
| `CreateTask.ps1` | Copies `InstallIvantiAgent.ps1` to `C:\Windows\Temp` and creates a startup scheduled task. |
| `InstallIvantiAgent.ps1` | Downloads the Ivanti agent package, installs it, waits for services, and removes the task when successful. |
| `DeleteTask.ps1` | Removes the scheduled task manually if needed. |

## Workflow

1. Deploy `CreateTask.ps1` to the target computer with Ivanti EPM.
2. `CreateTask.ps1` registers a startup task named `IvantiInstallAtStartup`.
3. At next startup, `InstallIvantiAgent.ps1` downloads the agent package from the configured web share.
4. The script installs the agent and waits for Ivanti services.
5. When at least one Ivanti service is running, the scheduled task is removed.

## Configuration

Edit these values in `InstallIvantiAgent.ps1`:

```powershell
$baseUrl = "http://epm2024.monlab.lan/share/ivanti/agent/"
$hostName = "epm2024.monlab.lan"
$ports = @(80, 443, 9593, 9594, 9595)
```

`epm2024.monlab.lan` is a lab placeholder. Replace it with your Ivanti EPM core server or web distribution point.

The agent file list is defined here:

```powershell
$fileNames = @(
    "d3873a1c.0",
    "EPM_Manifest",
    "EPMAgentInstaller.exe",
    "EPM2024Agent.txt"
)
```

Adapt the list to match your exported agent package.

## Usage

Run as Administrator:

```powershell
.\CreateTask.ps1
```

To remove the task manually:

```powershell
.\DeleteTask.ps1
```

## Notes

- The scheduled task runs as `NT AUTHORITY\SYSTEM`.
- The startup delay is randomized between 2 and 59 minutes to avoid all devices downloading at the same time.
- Logs are written to `C:\Windows\Temp\IvantiAgentInstall.log` and `C:\Windows\Temp\TaskRemoval.log`.
