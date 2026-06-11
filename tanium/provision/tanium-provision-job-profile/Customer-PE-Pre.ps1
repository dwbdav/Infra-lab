<# 
  DemoLab - Customer-PE-Pre
  Modal profile selector for Tanium OSD demo.
#>

if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', $PSCommandPath)
    Start-Process -FilePath 'powershell.exe' -ArgumentList $argsList -Wait
    exit $LASTEXITCODE
}

Import-Module C:\_T\TaniumOSD -ErrorAction Stop

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function New-Label {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [int]$Size = 10,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
    )

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = [System.Drawing.Point]::new($X, $Y)
    $label.Size = [System.Drawing.Size]::new($Width, $Height)
    $label.Font = [System.Drawing.Font]::new('Segoe UI', $Size, $Style)
    $label.ForeColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
    $label.BackColor = [System.Drawing.Color]::Transparent
    return $label
}

function Show-ProfileDialog {
    $profiles = @('Office', 'Developer', 'Assistant', 'Support')

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'DemoLab - Profile selection'
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MinimizeBox = $false
    $form.MaximizeBox = $false
    $form.ShowInTaskbar = $true
    $form.TopMost = $true
    $form.ClientSize = [System.Drawing.Size]::new(560, 260)
    $form.ControlBox = $false
    $form.AutoScaleMode = 'None'
    $form.BackColor = [System.Drawing.Color]::FromArgb(241, 245, 249)

    $title = New-Label -Text 'Select profile' -X 28 -Y 24 -Width 500 -Height 36 -Size 18 -Style ([System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($title)

    $subtitle = New-Label -Text 'Choose the business profile for this demo device.' -X 30 -Y 62 -Width 500 -Height 24 -Size 10
    $subtitle.ForeColor = [System.Drawing.Color]::FromArgb(71, 85, 105)
    $form.Controls.Add($subtitle)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = [System.Drawing.Point]::new(30, 104)
    $panel.Size = [System.Drawing.Size]::new(500, 70)
    $panel.BackColor = [System.Drawing.Color]::White
    $panel.BorderStyle = 'FixedSingle'
    $form.Controls.Add($panel)

    $profileLabel = New-Label -Text 'PROFILE' -X 18 -Y 13 -Width 110 -Height 22 -Size 9 -Style ([System.Drawing.FontStyle]::Bold)
    $profileLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
    $panel.Controls.Add($profileLabel)

    $combo = New-Object System.Windows.Forms.ComboBox
    $combo.Location = [System.Drawing.Point]::new(135, 18)
    $combo.Size = [System.Drawing.Size]::new(330, 28)
    $combo.DropDownStyle = 'DropDownList'
    $combo.Font = [System.Drawing.Font]::new('Segoe UI', 11)
    [void]$combo.Items.AddRange($profiles)
    $combo.SelectedItem = 'Developer'
    $panel.Controls.Add($combo)

    $validate = New-Object System.Windows.Forms.Button
    $validate.Text = 'Validate'
    $validate.Location = [System.Drawing.Point]::new(380, 198)
    $validate.Size = [System.Drawing.Size]::new(150, 38)
    $validate.Font = [System.Drawing.Font]::new('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $validate.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
    $validate.ForeColor = [System.Drawing.Color]::White
    $validate.FlatStyle = 'Flat'
    $validate.FlatAppearance.BorderSize = 0
    $form.Controls.Add($validate)
    $form.AcceptButton = $validate

    $validate.Add_Click({
        if (-not $combo.SelectedItem) {
            [void][System.Windows.Forms.MessageBox]::Show(
                'Please select a profile.',
                'Profile required',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

        $form.Tag = [string]$combo.SelectedItem
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })

    return $form.ShowDialog(), $form.Tag
}

$dialogResult, $SelectedProfile = Show-ProfileDialog

if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK -or [string]::IsNullOrWhiteSpace($SelectedProfile)) {
    exit 1
}

Set-OSDVariable -Name 'ProfileMetier' -Value $SelectedProfile
Set-OSDProgressDisplay -Message "Selected profile: $SelectedProfile"

Write-Host "Selected profile: $SelectedProfile"
exit 0
