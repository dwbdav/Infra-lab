# Variables globales
Add-Type -AssemblyName PresentationFramework

# Récupérer le chemin du script PowerShell
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$DefaultFolderPath = Join-Path $ScriptPath "AgentEPM"
$PsExecPath = Join-Path $ScriptPath "PsExec64.exe"

# Fonction pour créer l'interface graphique
function Show-InstallGUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Deploiement de fichier" Height="450" Width="600" ResizeMode="NoResize" WindowStartupLocation="CenterScreen">
    <Grid>
        <Label Content="Liste des ordinateurs (un par ligne):" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" FontSize="14"/>
        <TextBox Name="ComputerList" HorizontalAlignment="Left" Height="200" Margin="10,40,0,0" VerticalAlignment="Top" Width="560" AcceptsReturn="True" TextWrapping="Wrap"/>
        
        <Label Content="Chemin local du dossier a copier :" HorizontalAlignment="Left" Margin="10,250,0,0" VerticalAlignment="Top" FontSize="14"/>
        <TextBox Name="FolderPath" HorizontalAlignment="Left" Height="30" Margin="10,280,0,0" VerticalAlignment="Top" Width="560" Text="$DefaultFolderPath"/>

        <!-- Nouvelle case à cocher -->
        <CheckBox Name="ForceUninstall" Content="Force Uninstall avant installation" HorizontalAlignment="Left" Margin="10,320,0,0" VerticalAlignment="Top" FontSize="14"/>

        <Button Content="Install" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="0,0,0,10" Width="100" Height="30" Name="InstallButton"/>
    </Grid>
</Window>
"@

    # Charger le XAML et créer la fenêtre
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    # Associer les éléments de l'interface aux variables
    $ComputerList = $window.FindName("ComputerList")
    $FolderPath = $window.FindName("FolderPath")
    $ForceUninstall = $window.FindName("ForceUninstall")  # Case à cocher
    $InstallButton = $window.FindName("InstallButton")

    # Fonction exécutée lors du clic sur "Install"
    $InstallButton.Add_Click({
        $computers = $ComputerList.Text -split "`r`n" | Where-Object { $_ -ne "" }
        $folder = $FolderPath.Text
        $forceUninstallEnabled = $ForceUninstall.IsChecked  # Lire l'état de la case à cocher

        # Vérifier si le dossier par défaut existe
        if (-not (Test-Path $folder)) {
            [System.Windows.MessageBox]::Show("Le chemin du dossier specifie est invalide ou introuvable : $folder", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }

        # Vérifier si PsExec.exe existe
        if (-not (Test-Path $PsExecPath)) {
            [System.Windows.MessageBox]::Show("PsExec.exe est introuvable dans le repertoire du script : $ScriptPath", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }

        # Traitement des ordinateurs
        foreach ($computer in $computers) {
            Write-Host "----- $computer"
            try {
                # Vérifier l'accès à l'ordinateur
                if (!(Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
                    Write-Host "---------- ERROR $computer n'est pas accessible."
                    continue
                }



                # Vérifier si l'agent est déjà installé
                $remoteFilePath = "\\$computer\c$\Program Files (x86)\Ivanti\EPM Agent\EPMAgentInstaller.exe"
                if (-not (Test-Path $remoteFilePath) -or $forceUninstallEnabled) {
                    # Construire les chemins
                    $destination = "\\$computer\c$\windows\temp"
                    $exePath = "c:\windows\temp\EPMAgentInstaller.exe"

                    # Copier le dossier
                    if (Test-Path $destination) {
                        Write-Host "---------- Copy to $destination"
                        Copy-Item -Path $folder\* -Destination $destination -Recurse -Force
                    } else {
                        Write-Host "---------- ERROR Impossible d'acceder au chemin $destination"
                        continue
                    }


					# Si "Force Uninstall" est activé
					if ($forceUninstallEnabled) {
						Write-Host "---------- Arret des services Ivanti pour $computer"
						$killServicesCommand = "taskkill /F /FI ""SERVICES eq Ivanti*"""
						Start-Process -FilePath $PsExecPath -ArgumentList "\\$computer -accepteula -w c:\windows\temp cmd /c $killServicesCommand" -NoNewWindow -Wait

						Write-Host "---------- Execution de EPMAgentInstaller.exe /forceuninstall pour $computer"
						$epmForceUninstallCommand = """C:\Program Files (x86)\Ivanti\EPM Agent\EPMAgentInstaller.exe"" /forceuninstall"
						Start-Process -FilePath $PsExecPath -ArgumentList "\\$computer -accepteula -w c:\windows\temp cmd /c $epmForceUninstallCommand" -NoNewWindow -Wait

						Write-Host "---------- Execution du Force Uninstall via UninstallWinClient.exe pour $computer"
						$uninstallCommand = "c:\windows\temp\UninstallWinClient.exe /NOREBOOT"
						Start-Process -FilePath $PsExecPath -ArgumentList "\\$computer -accepteula -w c:\windows\temp cmd /c $uninstallCommand" -NoNewWindow -Wait
					}

                    # Lancer l'exécutable via PsExec
                    Write-Host "---------- Execution de $exePath via PsExec"
                    Start-Process -FilePath $PsExecPath -ArgumentList "\\$computer -accepteula -w c:\windows\temp $exePath" -NoNewWindow -Wait
                } else {
                    Write-Host "---------- ERROR L'agent est deja installe"
                }
            }
            catch {
                Write-Host "---------- ERROR lors du traitement de l'ordinateur $computer : $_"
            }
        }
        [System.Windows.MessageBox]::Show("Traitement termine.", "Information", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })

    # Afficher la fenêtre
    $window.ShowDialog() | Out-Null
}

# Afficher l'interface graphique
Show-InstallGUI
