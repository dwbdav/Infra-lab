# Install Ivanti EPM Agent with PsExec

PowerShell GUI used to deploy or reinstall an Ivanti EPM agent on remote Windows computers with `PsExec`.

## Files

| File | Description |
| --- | --- |
| `installgui.ps1` | WPF interface used to enter target computers and launch the deployment. |
| `PsExec64.exe` | PsExec binary used to run commands remotely. |
| `AgentEPM/` | Agent package copied to each target computer before installation. |
| `AgentEPM/EPMAgentInstaller.exe` | Ivanti EPM agent installer. |
| `AgentEPM/UninstallWinClient.exe` | Ivanti uninstall helper used when force uninstall is enabled. |
| `AgentEPM/EPM_Manifest` | Agent package manifest. |

## Requirements

- Run PowerShell as Administrator.
- The account running the tool must have administrative rights on target computers.
- Admin shares must be reachable on target computers, for example `\\computer\c$`.
- PowerShell execution policy must allow running the script.
- Network and firewall rules must allow PsExec remote execution.

## Usage

Run:

```powershell
.\installgui.ps1
```

In the GUI:

1. Enter one computer name or IP address per line.
2. Keep the default `AgentEPM` folder or select another local agent folder.
3. Enable `Force Uninstall avant installation` only when the existing agent must be removed first.
4. Click `Install`.

## Deployment Flow

The script performs these actions for each target computer:

1. Tests network connectivity.
2. Checks whether the Ivanti EPM agent is already installed.
3. Copies the local agent package to `C:\Windows\Temp` on the target.
4. Optionally stops Ivanti services and runs the uninstall helpers.
5. Starts `EPMAgentInstaller.exe` remotely with PsExec.

## Notes

- `AgentEPM` is a lab package and should be replaced with your own exported Ivanti EPM agent package when needed.
- Review the target list before launching the deployment.
- Test on one computer before running against a larger list.
