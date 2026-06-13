# 🖥️ installgui.ps1 – Ivanti EPM Agent Deployment via GUI

This PowerShell script provides a graphical interface (GUI) to remotely deploy the **Ivanti EPM Agent** to multiple computers using `PsExec`. It includes optional forced uninstallation of any existing agent installation before reinstalling.

---

## 🚀 Features

- Simple WPF-based graphical interface
- Input: List of target computers (one per line)
- Copies a local folder to each remote machine
- Option to **force uninstall** the existing agent
- Executes installation via `PsExec`
- Validates:
  - Folder path existence
  - PsExec availability
  - Network connectivity to each computer

---

## 🧰 Requirements

- Windows with PowerShell
- `PsExec64.exe` must be placed in the same directory as the script
- A local folder (`AgentEPM`) containing:
  - `EPMAgentInstaller.exe`
  - `UninstallWinClient.exe` (for forced uninstalls)

---

## 🛠️ How to Use

1. Run PowerShell as Administrator.
2. Execute the script:

   ```powershell
   .\installgui.ps1
   ```
3. In the GUI:
- Enter one computer name or IP per line
- Confirm or change the path to the local folder to copy
- Optional) Check the "Force Uninstall" box
- Click Install