#Requires -Version 5.1

Add-Type -AssemblyName PresentationFramework

# ============================================================================
# Configuration
# ============================================================================

$ConfigDirectory = Join-Path $env:LOCALAPPDATA "Ivanti-AddToTask"
$ConfigFile      = Join-Path $ConfigDirectory "Config.json"

function Get-Configuration {

    if (-not (Test-Path $ConfigFile)) {
        return $null
    }

    try {
        return Get-Content -Path $ConfigFile -Raw -ErrorAction Stop |
            ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Save-Configuration {

    param(
        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter(Mandatory)]
        [string]$Username
    )

    try {

        if (-not (Test-Path $ConfigDirectory)) {
            New-Item `
                -Path $ConfigDirectory `
                -ItemType Directory `
                -Force | Out-Null
        }

        $Configuration = [PSCustomObject]@{
            Server   = $Server
            Username = $Username
        }

        $Configuration |
            ConvertTo-Json |
            Set-Content `
                -Path $ConfigFile `
                -Encoding UTF8 `
                -Force
    }
    catch {
        # Configuration persistence failure must not block the application
    }
}

# ============================================================================
# STA check
# ============================================================================

if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Error "This script must be started in STA mode."
    exit 1
}

# ============================================================================
# Load configuration
# ============================================================================

$Configuration = Get-Configuration

$SavedServer   = ""
$SavedUsername = ""

if ($Configuration) {

    if ($Configuration.Server) {
        $SavedServer = $Configuration.Server
    }

    if ($Configuration.Username) {
        $SavedUsername = $Configuration.Username
    }
}

# ============================================================================
# XAML
# ============================================================================

[xml]$Xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Ivanti EPM - Add Devices To Task"
        Height="820"
        Width="620"
        MinHeight="700"
        MinWidth="520"
        WindowStartupLocation="CenterScreen"
        Background="#FFF5F5F5">

    <Window.Resources>

        <Style TargetType="Label">
            <Setter Property="Margin" Value="10,5,10,2"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="#FF333333"/>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Margin" Value="10,0,10,5"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="6"/>
            <Setter Property="BorderBrush" Value="#FFBBBBBB"/>
        </Style>

        <Style TargetType="PasswordBox">
            <Setter Property="Margin" Value="10,0,10,5"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="6"/>
            <Setter Property="BorderBrush" Value="#FFBBBBBB"/>
        </Style>

        <Style TargetType="Button">
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Height" Value="38"/>
            <Setter Property="Padding" Value="15,5"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>

    </Window.Resources>

    <Grid Margin="10">

        <Grid.RowDefinitions>

            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>

            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>

            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>

            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>

            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>

            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>

            <RowDefinition Height="Auto"/>
            <RowDefinition Height="160"/>

        </Grid.RowDefinitions>

        <!-- Server -->

        <Label Grid.Row="0"
               Content="Ivanti EPM Server"/>

        <TextBox Grid.Row="1"
                 Name="Server"
                 Height="34"
                 VerticalContentAlignment="Center"
                 ToolTip="Example: wfr440.pc.kiabi.fr"/>

        <!-- Username -->

        <Label Grid.Row="2"
               Content="Username"/>

        <TextBox Grid.Row="3"
                 Name="Username"
                 Height="34"
                 VerticalContentAlignment="Center"
                 ToolTip="Example: DOMAIN\User or user@domain"/>

        <!-- Password -->

        <Label Grid.Row="4"
               Content="Password"/>

        <PasswordBox Grid.Row="5"
                     Name="Password"
                     Height="34"
                     VerticalContentAlignment="Center"/>

        <!-- Task ID -->

        <Label Grid.Row="6"
               Content="Scheduled Task ID"/>

        <TextBox Grid.Row="7"
                 Name="TaskID"
                 Height="34"
                 VerticalContentAlignment="Center"
                 ToolTip="Ivanti EPM Scheduled Task ID"/>

        <!-- Computers -->

        <Label Grid.Row="8"
               Content="Computers"/>

        <Grid Grid.Row="9">

            <Grid.RowDefinitions>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <TextBox Grid.Row="0"
                     Name="PC"
                     AcceptsReturn="True"
                     AcceptsTab="False"
                     TextWrapping="NoWrap"
                     VerticalScrollBarVisibility="Auto"
                     HorizontalScrollBarVisibility="Auto"
                     FontFamily="Consolas"
                     FontSize="13"/>

            <TextBlock Grid.Row="1"
                       Margin="12,2,10,8"
                       Foreground="#FF777777"
                       FontSize="11"
                       Text="One computer per line. Comma and semicolon separators are also supported."/>

        </Grid>

        <!-- Buttons -->

        <Grid Grid.Row="10"
              Margin="5">

            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <TextBlock Grid.Column="0"
                       Name="Counter"
                       VerticalAlignment="Center"
                       Margin="5"
                       FontWeight="SemiBold"
                       Foreground="#FF555555"
                       Text="Ready"/>

            <Button Grid.Column="1"
                    Name="Clear"
                    Content="Clear"
                    Width="100"
                    Background="#FFE0E0E0"
                    Foreground="#FF333333"/>

            <Button Grid.Column="2"
                    Name="Add"
                    Content="Add To Task"
                    Width="140"
                    Background="#FF1976D2"
                    Foreground="White"/>

        </Grid>

        <!-- Progress -->

        <ProgressBar Grid.Row="11"
                     Name="Progress"
                     Height="18"
                     Margin="10,0,10,10"
                     Minimum="0"
                     Maximum="100"
                     Value="0"/>

        <!-- Log -->

        <Label Grid.Row="12"
               Content="Operation log"/>

        <TextBox Grid.Row="13"
                 Name="Log"
                 IsReadOnly="True"
                 AcceptsReturn="True"
                 TextWrapping="NoWrap"
                 VerticalScrollBarVisibility="Auto"
                 HorizontalScrollBarVisibility="Auto"
                 FontFamily="Consolas"
                 FontSize="11"
                 Background="#FF202020"
                 Foreground="#FFE8E8E8"/>

    </Grid>
</Window>
'@

# ============================================================================
# Load WPF
# ============================================================================

$Reader = [System.Xml.XmlNodeReader]::new($Xaml)

try {
    $Form = [Windows.Markup.XamlReader]::Load($Reader)
}
catch {
    Write-Error "Unable to load WPF form: $($_.Exception.Message)"
    exit 1
}

$Xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    Set-Variable -Name $_.Name -Value $Form.FindName($_.Name)
}

# ============================================================================
# Restore saved configuration
# ============================================================================

if (-not [string]::IsNullOrWhiteSpace($SavedServer)) {
    $Server.Text = $SavedServer
}

if (-not [string]::IsNullOrWhiteSpace($SavedUsername)) {
    $Username.Text = $SavedUsername
}

# ============================================================================
# Functions
# ============================================================================

function Add-Log {

    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    $Timestamp = Get-Date -Format "HH:mm:ss"

    $Log.AppendText(
        "[$Timestamp] $Message" +
        [Environment]::NewLine
    )

    $Log.ScrollToEnd()
}

function Update-GUI {

    $Form.Dispatcher.Invoke(
        [Action]{},
        [Windows.Threading.DispatcherPriority]::Background
    )
}

function Get-ExceptionMessage {

    param(
        [Parameter(Mandatory)]
        [System.Exception]$Exception
    )

    $Messages = @()
    $CurrentException = $Exception

    while ($CurrentException) {

        if (-not [string]::IsNullOrWhiteSpace($CurrentException.Message)) {
            $Messages += $CurrentException.Message
        }

        $CurrentException = $CurrentException.InnerException
    }

    return ($Messages -join " | ")
}

function Unlock-Interface {

    $Add.IsEnabled      = $true
    $Clear.IsEnabled    = $true
    $Server.IsEnabled   = $true
    $Username.IsEnabled = $true
    $Password.IsEnabled = $true
    $TaskID.IsEnabled   = $true
    $PC.IsEnabled       = $true
}

function Lock-Interface {

    $Add.IsEnabled      = $false
    $Clear.IsEnabled    = $false
    $Server.IsEnabled   = $false
    $Username.IsEnabled = $false
    $Password.IsEnabled = $false
    $TaskID.IsEnabled   = $false
    $PC.IsEnabled       = $false
}

# ============================================================================
# Clear button
# ============================================================================

$Clear.Add_Click({

    $TaskID.Clear()
    $PC.Clear()
    $Log.Clear()

    $Progress.Value = 0
    $Counter.Text = "Ready"

    # Keep server and username
    # Never keep the password
    $Password.Clear()

    $TaskID.Focus()
})

# ============================================================================
# Add To Task
# ============================================================================

$Add.Add_Click({

    # ------------------------------------------------------------------------
    # Server
    # ------------------------------------------------------------------------

    $ServerName = $Server.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($ServerName)) {

        [System.Windows.MessageBox]::Show(
            "Server name cannot be empty.",
            "Ivanti EPM",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )

        $Server.Focus()
        return
    }

    # Accept server name or complete URL
    $ServerName = $ServerName `
        -replace '^https?://', '' `
        -replace '/.*$', ''

    $Server.Text = $ServerName

    $WebServiceUrl = "https://$ServerName/MBSDKService/MsgSDK.asmx"

    # ------------------------------------------------------------------------
    # Username
    # ------------------------------------------------------------------------

    $UserNameValue = $Username.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($UserNameValue)) {

        [System.Windows.MessageBox]::Show(
            "Username cannot be empty.",
            "Ivanti EPM",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )

        $Username.Focus()
        return
    }

    # ------------------------------------------------------------------------
    # Password
    # ------------------------------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($Password.Password)) {

        [System.Windows.MessageBox]::Show(
            "Password cannot be empty.",
            "Ivanti EPM",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )

        $Password.Focus()
        return
    }

    # Create credential in memory
    $SecurePassword = $Password.SecurePassword

    $Credential = New-Object `
        System.Management.Automation.PSCredential(
            $UserNameValue,
            $SecurePassword
        )

    # Save server + username only
    Save-Configuration `
        -Server $ServerName `
        -Username $UserNameValue

    # ------------------------------------------------------------------------
    # Task ID
    # ------------------------------------------------------------------------

    $TaskText = $TaskID.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($TaskText)) {

        [System.Windows.MessageBox]::Show(
            "Task ID cannot be empty.",
            "Ivanti EPM",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )

        $TaskID.Focus()
        return
    }

    [int]$Task = 0

    if (-not [int]::TryParse($TaskText, [ref]$Task)) {

        [System.Windows.MessageBox]::Show(
            "Task ID must be numeric.",
            "Ivanti EPM",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )

        $TaskID.Focus()
        return
    }

    if ($Task -le 0) {

        [System.Windows.MessageBox]::Show(
            "Task ID must be greater than zero.",
            "Ivanti EPM",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )

        $TaskID.Focus()
        return
    }

    # ------------------------------------------------------------------------
    # Computer list
    # ------------------------------------------------------------------------

    $ComputerList = @(
        $PC.Text -split '[,;\r\n\t]+' |
            ForEach-Object {
                $_.Trim()
            } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } |
            Select-Object -Unique
    )

    if ($ComputerList.Count -eq 0) {

        [System.Windows.MessageBox]::Show(
            "Computer list cannot be empty.",
            "Ivanti EPM",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )

        $PC.Focus()
        return
    }

    # ------------------------------------------------------------------------
    # Prepare interface
    # ------------------------------------------------------------------------

    Lock-Interface

    $Log.Clear()

    $Progress.Minimum = 0
    $Progress.Maximum = $ComputerList.Count
    $Progress.Value   = 0

    $Counter.Text = "Connecting..."

    Add-Log "Server            : $ServerName"
    Add-Log "Username          : $UserNameValue"
    Add-Log "Web Service       : $WebServiceUrl"
    Add-Log "Scheduled Task ID : $Task"
    Add-Log "Computers         : $($ComputerList.Count)"
    Add-Log ""
    Add-Log "Connecting to Ivanti EPM..."

    Update-GUI

    # ------------------------------------------------------------------------
    # Connect to MBSDK
    # ------------------------------------------------------------------------

    try {

        $Ldws = New-WebServiceProxy `
            -Uri $WebServiceUrl `
            -Credential $Credential `
            -ErrorAction Stop

        Add-Log "Connection successful."
    }
    catch {

        $ErrorMessage = Get-ExceptionMessage $_.Exception

        Add-Log "ERROR: Unable to connect to Ivanti EPM."
        Add-Log $ErrorMessage

        [System.Windows.MessageBox]::Show(
            "Unable to connect to Ivanti EPM.`r`n`r`n$ErrorMessage",
            "Connection error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )

        Unlock-Interface

        $Counter.Text = "Connection failed"

        return
    }

    # ------------------------------------------------------------------------
    # Add computers
    # ------------------------------------------------------------------------

    $Success = 0
    $Failed  = 0
    $Current = 0

    Add-Log ""
    Add-Log "Starting operation..."
    Add-Log "------------------------------------------------------------"

    foreach ($ComputerName in $ComputerList) {

        $Current++

        $Counter.Text = "$Current / $($ComputerList.Count) - $ComputerName"

        try {

            [void]$Ldws.AddDeviceToScheduledTask(
                $Task,
                $ComputerName
            )

            Add-Log "[OK]    $ComputerName"

            $Success++
        }
        catch {

            $ErrorMessage = Get-ExceptionMessage $_.Exception

            Add-Log "[ERROR] $ComputerName"
            Add-Log "        $ErrorMessage"

            $Failed++
        }

        $Progress.Value = $Current

        Update-GUI
    }

    # ------------------------------------------------------------------------
    # Summary
    # ------------------------------------------------------------------------

    Add-Log "------------------------------------------------------------"
    Add-Log "Operation completed."
    Add-Log "Success : $Success"
    Add-Log "Failed  : $Failed"

    $Counter.Text = "Completed - Success: $Success / Failed: $Failed"

    Unlock-Interface

    # Clear password after operation
    $Password.Clear()

    if ($Failed -eq 0) {

        [System.Windows.MessageBox]::Show(
            "$Success computer(s) successfully added to Task $Task.",
            "Ivanti EPM",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        )
    }
    else {

        [System.Windows.MessageBox]::Show(
            "Operation completed.`r`n`r`nSuccess: $Success`r`nFailed: $Failed`r`n`r`nCheck the operation log for details.",
            "Ivanti EPM",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )
    }
})

# ============================================================================
# Save configuration when closing
# ============================================================================

$Form.Add_Closing({

    $ServerName   = $Server.Text.Trim()
    $UsernameValue = $Username.Text.Trim()

    if (
        -not [string]::IsNullOrWhiteSpace($ServerName) -and
        -not [string]::IsNullOrWhiteSpace($UsernameValue)
    ) {

        $ServerName = $ServerName `
            -replace '^https?://', '' `
            -replace '/.*$', ''

        Save-Configuration `
            -Server $ServerName `
            -Username $UsernameValue
    }
})

# ============================================================================
# Initial focus
# ============================================================================

$Form.Add_ContentRendered({

    if ([string]::IsNullOrWhiteSpace($Server.Text)) {

        $Server.Focus()
    }
    elseif ([string]::IsNullOrWhiteSpace($Username.Text)) {

        $Username.Focus()
    }
    else {

        # Usually the only information missing after first launch
        $Password.Focus()
    }
})

# ============================================================================
# Show GUI
# ============================================================================

$Form.ShowDialog() | Out-Null
