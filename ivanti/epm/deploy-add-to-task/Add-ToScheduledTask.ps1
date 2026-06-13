#Requires -Version 5.1

param(
    [Parameter(Mandatory)]
    [uri]$WebServiceUrl,

    [pscredential]$Credential
)

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

if (-not $Credential) {
    $Credential = Get-Credential
}

[xml]$Xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Add To Task" Height="500" Width="300"
        WindowStartupLocation="CenterScreen"
        Background="#FFFAFAFA">
    <Window.Resources>
        <Style TargetType="Label">
            <Setter Property="Margin" Value="10,5,10,0"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="#FF444444"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Margin" Value="10,0,10,10"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Padding" Value="5"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Margin" Value="10,10,10,10"/>
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="Height" Value="40"/>
            <Setter Property="Background" Value="#FF1976D2"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Label Content="Task ID:" Grid.Row="0" HorizontalAlignment="Left"/>
        <TextBox Name="TaskID" Grid.Row="1" HorizontalAlignment="Stretch"/>

        <Label Content="Computers:" Grid.Row="2" HorizontalAlignment="Left" VerticalAlignment="Top"/>
        <TextBox Name="PC" Grid.Row="2" VerticalAlignment="Top" AcceptsReturn="True" TextWrapping="Wrap" HorizontalAlignment="Stretch" Height="300"/>

        <Button Content="Add to Task" Name="Add" Grid.Row="3" HorizontalAlignment="Center" Width="150"/>
    </Grid>
</Window>
'@

$reader = [System.Xml.XmlNodeReader]::new($Xaml)
try {
    $form = [Windows.Markup.XamlReader]::Load($reader)
}
catch {
    Write-Error "Unable to load WPF form. Start PowerShell with -STA and verify .NET Framework is available. $($_.Exception.Message)"
    exit 1
}

$Xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    Set-Variable -Name $_.Name -Value $form.FindName($_.Name)
}

$Add.Add_Click({
    $task = $TaskID.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($task)) {
        Write-Host "Error: Task ID cannot be empty."
        return
    }

    $computerList = $PC.Text -split "(`r`n|`n|`r)" |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    if (-not $computerList) {
        Write-Host "Error: computer list cannot be empty."
        return
    }

    try {
        $ldws = New-WebServiceProxy -Uri $WebServiceUrl.AbsoluteUri -Credential $Credential
    }
    catch {
        Write-Host "Unable to connect to Ivanti EPM web service: $($_.Exception.Message)"
        return
    }

    foreach ($computerName in $computerList) {
        try {
            $ldws.AddDeviceToScheduledTask($task, $computerName)
            Write-Host "Successfully added: $computerName"
        }
        catch {
            Write-Host "Error adding $computerName : $($_.Exception.Message)"
        }
    }

    Write-Host "Operation completed."
})

$form.ShowDialog() | Out-Null
