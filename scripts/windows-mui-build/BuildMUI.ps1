#requires -version 5.1
<#! 
  Title: Build Windows 11 Multi-Index (MUI) — GUI Pro (v2.3)
  UI:
    • Paths via TableLayoutPanel (DPI safe)
    • Boutons flat + hover + coins arrondis
    • Log en ListView: Time | Level | Message (menu Copy/Clear)
    • Popup “build terminé” + son
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --------------------------- Globals & Helpers ---------------------------
$global:Form        = $null
$global:LogBox      = $null   # sera le ListView
$global:StatusLabel = $null
$ToolTip            = New-Object System.Windows.Forms.ToolTip

function Write-Log {
  param([string]$Message,[ValidateSet('INFO','WARN','ERROR')]$Level='INFO')
  $ts   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
  $line = "[$ts] $Level  $Message"

  # console (utile si script lancé hors GUI)
  switch ($Level) {
    'ERROR' { Write-Host $line -ForegroundColor Red }
    'WARN'  { Write-Host $line -ForegroundColor Yellow }
    default { Write-Host $line -ForegroundColor Gray }
  }

  # GUI
  if ($global:LogBox -and -not $global:LogBox.IsDisposed) {
    if ($global:LogBox -is [System.Windows.Forms.ListView]) {
      $item = New-Object System.Windows.Forms.ListViewItem($ts)
      [void]$item.SubItems.Add($Level)
      [void]$item.SubItems.Add($Message)
      switch($Level){
        'ERROR' { $item.ForeColor = [Drawing.Color]::FromArgb(210,39,30) }
        'WARN'  { $item.ForeColor = [Drawing.Color]::FromArgb(185,120,0) }
        default { $item.ForeColor = [Drawing.Color]::FromArgb(45,45,45) }
      }
      [void]$global:LogBox.Items.Add($item)
      $global:LogBox.EnsureVisible($global:LogBox.Items.Count-1)
    } else {
      $global:LogBox.AppendText($line + [Environment]::NewLine)
      $global:LogBox.SelectionStart = $global:LogBox.Text.Length
      $global:LogBox.ScrollToCaret()
    }
  }

  if ($global:StatusLabel -and !$global:StatusLabel.IsDisposed) {
    $global:StatusLabel.Text = $Message
  }
}

function Assert-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = [Security.Principal.WindowsPrincipal]::new($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show('Run this script as Administrator.','Privilege required','OK','Error') | Out-Null
    throw 'Not running as Administrator.'
  }
}

function Ensure-ProjectSubfolders([string]$Root){
  if ([string]::IsNullOrWhiteSpace($Root)) { throw 'Please set the project root folder.' }
  foreach($s in 'ISO','WinPE_OCs','Export','SXS'){
    $path = Join-Path $Root $s
    if (-not (Test-Path $path)){
      Write-Log "Create missing: $path"
      New-Item -ItemType Directory -Force -Path $path | Out-Null
    }
  }
}

function Ensure-LocalSubfolders([string]$Root){
  if ([string]::IsNullOrWhiteSpace($Root)) { throw 'Please set the local work root.' }
  foreach($s in 'MountWinPE','MountWinRE','MountInstall','scratch','distribution'){
    $path = Join-Path $Root $s
    if (-not (Test-Path $path)){
      Write-Log "Create missing local: $path"
      New-Item -ItemType Directory -Force -Path $path | Out-Null
    }
  }
}

# --------------------------- Core functions ---------------------------
function CleanupSafe {
  Param(
    [parameter(Mandatory=$true)][string]$DossierMountWindows,
    [parameter(Mandatory=$true)][string]$DossierMountWinPE,
    [parameter(Mandatory=$true)][string]$DossierMountWinRE,
    [parameter(Mandatory=$true)][string]$DossierMountScratch,
    [parameter(Mandatory=$true)][string]$DossierTravail
  )
  Write-Log 'Cleanup (safe) started'
  $oldEAP = $ErrorActionPreference
  $ErrorActionPreference = 'SilentlyContinue'

  try { & dism.exe /English /Cleanup-Wim 2>$null | Out-Null } catch {}

  foreach ($p in @($DossierMountWinPE,$DossierMountWinRE,$DossierMountWindows)) {
    try { Dismount-WindowsImage -Path $p -Discard -ErrorAction Stop | Out-Null; Write-Log "Dismounted: $p" } catch {}
  }

  try {
    $mounted = & dism.exe /English /Get-MountedWimInfo 2>$null
    if ($LASTEXITCODE -eq 0 -and $mounted) {
      $orphans = foreach ($ln in $mounted) { if ($ln -like 'Mount Dir :*') { ($ln.Split(':',2)[1]).Trim() } }
      foreach ($m in $orphans) { try { & dism.exe /Unmount-Wim /MountDir:"$m" /Discard 2>$null | Out-Null } catch {} }
    }
  } catch {}

  foreach ($p in @($DossierMountWinPE,$DossierMountWindows,$DossierMountWinRE,$DossierMountScratch,$DossierTravail)) {
    try { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue } catch {}
  }

  $ErrorActionPreference = $oldEAP
  Write-Log 'Cleanup (safe) finished'
}

function Prepare {
  Param(
    [parameter(Mandatory=$true)][String]$DossierMountWindows,
    [parameter(Mandatory=$true)][String]$DossierMountWinPE,
    [parameter(Mandatory=$true)][String]$DossierMountWinRE,
    [parameter(Mandatory=$true)][String]$DossierMountScratch,
    [parameter(Mandatory=$true)][String]$DossierTravail
  )
  Write-Log 'Prepare mount/scratch folders'
  $ErrorActionPreference = 'SilentlyContinue'
  New-Item -ItemType Directory -Force -Path $DossierMountWindows,$DossierMountWinPE,$DossierMountWinRE,$DossierMountScratch,$DossierTravail | Out-Null
  $ErrorActionPreference = 'Continue'
}

Function CopierFichierInstallation {
  Param(
    [parameter(Mandatory=$true)][String]$LangueBase,
    [parameter(Mandatory=$true)][String]$DossierExport,
    [parameter(Mandatory=$true)][String]$DossierAvecISO
  )
  Write-Log 'Copy installation files'
  Write-Log "Copy $LangueBase to $DossierExport"
  $ListISO = Get-ChildItem -Path $DossierAvecISO | Where-Object {$_.Name -like '*.ISO*'}
  foreach ($ISO in $ListISO) {
    $PatchISO = $ISO.FullName
    Write-Log $PatchISO
    $vol = Mount-DiskImage -ImagePath $PatchISO -PassThru | Get-DiskImage | Get-Volume
    $DossierLanguerecherche = $vol.DriveLetter+':\sources\'+$LangueBase
    $IsoLangueRecherche     = "$($vol.DriveLetter):\"
    if(Test-Path $DossierLanguerecherche) {
      Write-Log "Robocopy $IsoLangueRecherche $DossierExport"
      Robocopy "$IsoLangueRecherche" "$DossierExport" /MIR | Out-Null
    }
    Dismount-DiskImage -ImagePath $PatchISO | Out-Null
  }
}

Function CopierSXS {
  Param(
    [parameter(Mandatory=$true)][String]$DossierExportsxs,
    [parameter(Mandatory=$true)][String]$DossierAvecISO
  )
  Write-Log 'Collect SXS language sources'
  $LanguageCode = 'bg-bg','cs-cz','da-dk','de-de','el-gr','en-gb','en-us','es-es','es-mx','et-ee','fi-fi','fr-ca','fr-fr','hr-hr','hu-hu','it-it','ja-jp','ko-kr','lt-lt','lv-lv','nb-no','nl-nl','pl-pl','pt-br','pt-pt','ro-ro','ru-ru','sk-sk','sl-si','sv-se','tr-tr','uk-ua','zh-cn','zh-tw'
  $ListISO = Get-ChildItem -Path $DossierAvecISO | Where-Object {$_.Name -like '*.ISO*'}
  foreach ($ISO in $ListISO) {
    $PatchISO = $ISO.FullName
    $vol = Mount-DiskImage -ImagePath $PatchISO -PassThru | Get-DiskImage | Get-Volume
    foreach ($Item in $LanguageCode) {
      $TestLP  = $vol.DriveLetter+':\sources\'+$Item
      $Testsxs = $vol.DriveLetter+':\sources\sxs'
      if((Test-Path -Path $TestLP) -and (Test-Path -Path $Testsxs)) {
        Write-Log "copy : $DossierExportsxs\$Item"
        Robocopy "$Testsxs" "$DossierExportsxs\$Item" /MIR | Out-Null
      }
    }
    Dismount-DiskImage -ImagePath $PatchISO | Out-Null
  }
}

Function MontageWim {
  Param(
    [parameter(Mandatory=$true)][String]$DossierMount,
    [parameter(Mandatory=$true)][String]$ImageWim,
    [parameter(Mandatory=$true)][String]$IndexWim
  )
  Write-Log 'Mount WIM'
  Write-Log $ImageWim
  Write-Log $DossierMount
  Set-ItemProperty -Path $ImageWim -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
  Write-Log "mount $ImageWim"
  Mount-WindowsImage -ImagePath $ImageWim -Index $IndexWim -Path $DossierMount
}

Function SaveImageWim {
  Param([parameter(Mandatory=$true)][String]$DossierMount)
  Write-Log 'Save & Unmount WIM'
  Write-Log "unmount $DossierMount"
  Dismount-WindowsImage -Path $DossierMount -Save
}

# WinPE languages
Function AjoutLangueWinPE {
  Param(
    [parameter(Mandatory=$true)][string]$DossierMountWinPE,
    [parameter(Mandatory=$true)][string]$DossierAvecISO,
    [parameter(Mandatory=$true)][string]$OSclientOuServer, # 'Client' or 'Server'
    [parameter(Mandatory=$true)][string]$DossierLangueWinPE,
    [parameter(Mandatory=$true)][string]$DossierExport,
    [parameter(Mandatory=$true)][string]$LangueDeBase
  )
  Write-Log 'Add WinPE languages'
  if (-not (Test-Path -LiteralPath $DossierLangueWinPE)) { throw "WinPE_OCs folder not found: $DossierLangueWinPE" }

  $LanguageCode = 'bg-bg','cs-cz','da-dk','de-de','el-gr','en-gb','en-us','es-es','es-mx','et-ee','fi-fi','fr-ca','fr-fr','hr-hr','hu-hu','it-it','ja-jp','ko-kr','lt-lt','lv-lv','nb-no','nl-nl','pl-pl','pt-br','pt-pt','ro-ro','sk-sk','sl-si','sv-se','tr-tr','uk-ua','zh-cn','zh-tw'

  function Add-CabIfExists([string]$mount,[string]$cabPath){
    if (Test-Path -LiteralPath $cabPath) {
      Write-Log ("Add-WindowsPackage: {0}" -f ([IO.Path]::GetFileName($cabPath)))
      Add-WindowsPackage -Path $mount -PackagePath $cabPath -ErrorAction Stop | Out-Null
      return $true
    } else { Write-Log "SKIP missing package: $cabPath"; return $false }
  }

  MontageWim -DossierMount $DossierMountWinPE -ImageWim (Join-Path $DossierExport 'sources/boot.wim') -IndexWim 2

  $ListISO = Get-ChildItem -Path $DossierAvecISO | Where-Object { $_.Name -like '*.ISO*' }
  foreach ($ISO in $ListISO) {
    $PatchISO = $ISO.FullName
    $vol = Mount-DiskImage -ImagePath $PatchISO -PassThru | Get-DiskImage | Get-Volume

    foreach ($Item in $LanguageCode) {
      $TestLP = $vol.DriveLetter+':\sources\'+$Item
      if (Test-Path -LiteralPath $TestLP) {
        if ($LangueDeBase -ne $Item) {
          $lp = Join-Path (Join-Path $DossierLangueWinPE $Item) 'lp.cab'
          [void](Add-CabIfExists -mount $DossierMountWinPE -cabPath $lp)

          if ($OSclientOuServer -eq 'Client') { $cabNames = @("WinPE-Setup_${Item}.cab","WinPE-Setup-Client_${Item}.cab") }
          else                                 { $cabNames = @("WinPE-Setup_${Item}.cab","WinPE-Setup-Server_${Item}.cab") }

          foreach ($cab in $cabNames) {
            $rootPath = Join-Path $DossierLangueWinPE $cab
            $altPath  = Join-Path (Join-Path $DossierLangueWinPE $Item) $cab
            if (-not (Add-CabIfExists -mount $DossierMountWinPE -cabPath $rootPath)) { [void](Add-CabIfExists -mount $DossierMountWinPE -cabPath $altPath) }
          }
        }
      }
    }

    foreach ($ItemFont in 'ja-jp','ko-kr','zh-hk','zh-cn','zh-tw') {
      $TestLP = $vol.DriveLetter+':\sources\'+$ItemFont
      if (Test-Path -LiteralPath $TestLP) {
        $fontCab = Join-Path $DossierLangueWinPE ("WinPE-FontSupport-{0}.cab" -f $ItemFont)
        [void](Add-CabIfExists -mount $DossierMountWinPE -cabPath $fontCab)
      }
    }
    $TestTH = $vol.DriveLetter+':\sources\th-TH'
    if (Test-Path -LiteralPath $TestTH) { [void](Add-CabIfExists -mount $DossierMountWinPE -cabPath (Join-Path $DossierLangueWinPE 'WinPE-FontSupport-WinRE.cab')) }

    Dismount-DiskImage -ImagePath $PatchISO | Out-Null
  }

  SaveImageWim -DossierMount $DossierMountWinPE
}

Function AjoutLangueDistribution {
  Param(
    [parameter(Mandatory=$true)][String]$DossierExport,
    [parameter(Mandatory=$true)][String]$DossierAvecISO
  )
  Write-Log 'Copy distribution languages'
  $LanguageCode = 'bg-bg','cs-cz','da-dk','de-de','el-gr','en-gb','en-us','es-es','es-mx','et-ee','fi-fi','fr-ca','fr-fr','hr-hr','hu-hu','it-it','ja-jp','ko-kr','lt-lt','lv-lv','nb-no','nl-nl','pl-pl','pt-br','pt-pt','ro-ro','ru-ru','sk-sk','sl-si','sv-se','tr-tr','uk-ua','zh-cn','zh-tw'
  $ListISO = Get-ChildItem -Path $DossierAvecISO | Where-Object {$_.Name -like '*.ISO*'}
  foreach ($ISO in $ListISO) {
    $PatchISO = $ISO.FullName
    $vol = Mount-DiskImage -ImagePath $PatchISO -PassThru | Get-DiskImage | Get-Volume
    foreach ($Item in $LanguageCode) {
      $TestLP = $vol.DriveLetter+':\sources\'+$Item
      if(Test-Path -Path $TestLP){ Write-Log "copy : $TestLP"; Robocopy "$TestLP" "$DossierExport\Sources\$Item" /MIR | Out-Null }
    }
    Dismount-DiskImage -ImagePath $PatchISO | Out-Null
  }
}

function ActivateNetFX3 {
  param(
    [parameter(Mandatory=$true)][string]$DossierMountWindows,
    [parameter(Mandatory=$true)][string]$DossierExport,
    [parameter(Mandatory=$true)][string]$DossierExportsxs,
    [parameter(Mandatory=$true)][string]$IndexName
  )
  $listwim = Get-WindowsImage -ImagePath "$DossierExport\sources\install.wim"
  foreach ($Version in $listwim) {
    $NameWindowsVersion = $Version.ImageName
    $IndexCheck         = $Version.ImageIndex
    Write-Log "$NameWindowsVersion VS $IndexName"
    If (($NameWindowsVersion -eq $IndexName) -or ($IndexName -eq 'ALL')) {
      Write-Log "Enable NetFx3 : $NameWindowsVersion"
      MontageWim -DossierMount $DossierMountWindows -ImageWim "$DossierExport\sources\install.wim" -IndexWim $IndexCheck
      $SourceSXS = Join-Path $DossierExportsxs $NameWindowsVersion
      Write-Log "SourcesSXS=$SourceSXS"
      Enable-WindowsOptionalFeature -Path $DossierMountWindows -FeatureName 'NetFx3' -All -Source $SourceSXS | Out-Null
      SaveImageWim -DossierMount $DossierMountWindows
    }
  }
}

Function FakeLangIni {
  Param(
    [parameter(Mandatory=$true)][String]$DossierExport,
    [parameter(Mandatory=$true)][String]$Languebase,
    [parameter(Mandatory=$true)][String]$DossierAvecISO
  )
  Write-Log 'Generate lang.ini'
  $LanguageCode = 'bg-bg','cs-cz','da-dk','de-de','el-gr','en-gb','en-us','es-es','es-mx','et-ee','fi-fi','fr-ca','fr-fr','hr-hr','hu-hu','it-it','ja-jp','ko-kr','lt-lt','lv-lv','nb-no','nl-nl','pl-pl','pt-pt','ro-ro','ru-ru','sk-sk','sl-si','sv-se','tr-tr','uk-ua','zh-cn','zh-tw'
  Remove-item "$DossierExport\Sources\lang.ini" -Force -Recurse -ErrorAction SilentlyContinue
  ''                         | Out-File "$DossierExport\Sources\lang.ini" -Append -Encoding UTF8 -Force
  '[Available UI Languages]' | Out-File "$DossierExport\Sources\lang.ini" -Append -Encoding UTF8 -Force
  "$Languebase = 3"          | Out-File "$DossierExport\Sources\lang.ini" -Append -Encoding UTF8 -Force
  $ListISO = Get-ChildItem -Path $DossierAvecISO | Where-Object {$_.Name -like '*.ISO*'}
  foreach ($ISO in $ListISO) {
    $PatchISO = $ISO.FullName
    $vol = Mount-DiskImage -ImagePath $PatchISO -PassThru | Get-DiskImage | Get-Volume
    foreach ($Item in $LanguageCode) {
      $TestLP = $vol.DriveLetter+':\sources\'+$Item
      if(Test-Path -Path $TestLP){ if ($Item -notlike "*$Languebase*") { "$Item = 2" | Out-File "$DossierExport\Sources\lang.ini" -Append -Encoding UTF8 -Force } }
    }
    Dismount-DiskImage -ImagePath $PatchISO | Out-Null
  }
  ''                      | Out-File "$DossierExport\Sources\lang.ini" -Append -Encoding UTF8 -Force
  '[Fallback Languages]'  | Out-File "$DossierExport\Sources\lang.ini" -Append -Encoding UTF8 -Force
  "$Languebase = $Languebase" | Out-File "$DossierExport\Sources\lang.ini" -Append -Encoding UTF8 -Force
}

Function Wimindex {
  Param(
    [parameter(Mandatory=$true)][String]$DossierTravail,
    [parameter(Mandatory=$true)][String]$DossierExport,
    [parameter(Mandatory=$true)][String]$IndexName,
    [parameter(Mandatory=$true)][String]$DossierAvecISO
  )
  Write-Log 'Build reduced install.wim (selected edition)'
  $LanguageCode = 'bg-bg','cs-cz','da-dk','de-de','el-gr','en-gb','en-us','es-es','es-mx','et-ee','fi-fi','fr-ca','fr-fr','hr-hr','hu-hu','it-it','ja-jp','ko-kr','lt-lt','lv-lv','nb-no','nl-nl','pl-pl','pt-br','pt-pt','ro-ro','sk-sk','sl-si','sv-se','tr-tr','uk-ua','zh-cn','zh-tw'
  if (Test-Path "$DossierExport\Sources\install.wim") { Remove-item "$DossierExport\Sources\install.wim" -Force -Recurse }
  $ListISO = Get-ChildItem -Path $DossierAvecISO | Where-Object {$_.Name -like '*.ISO*'}
  foreach ($ISO in $ListISO) {
    $PatchISO = $ISO.FullName
    $vol = Mount-DiskImage -ImagePath $PatchISO -PassThru | Get-DiskImage | Get-Volume
    foreach ($Item in $LanguageCode) {
      $TestLP = $vol.DriveLetter+':\sources\'+$Item
      if(Test-Path -Path $TestLP){
        $LettreISO = "$($vol.DriveLetter):\"
        Write-Log "copy : $PatchISO"
        Robocopy "$LettreISO" "$DossierTravail" /MIR  | Out-Null
        $listwim = Get-WindowsImage -ImagePath "$DossierTravail\sources\install.wim"
        foreach ($Version in $listwim) {
          $NameWindowsVersion = $Version.ImageName
          $IndexCheck         = $Version.ImageIndex
          $NameWindowsVersion = $NameWindowsVersion -replace [char]160,' '
          $NameWindowsVersion = $NameWindowsVersion -replace [char]201,'É'
          $NameWindowsVersion = $NameWindowsVersion.Replace('Éducation','Education').Replace('Entreprise','Enterprise').Replace('Professionnel','Pro').Replace('pour les Stations de travail','for Workstations').Trim()
          Write-Log "$NameWindowsVersion VS $IndexName"
          If ($NameWindowsVersion -eq $IndexName) {
            Write-Log "export : $DossierExport\Sources\install.wim => $NameWindowsVersion"
            Dism /export-image /SourceImageFile:"$DossierTravail\sources\install.wim" /Sourceindex:$IndexCheck /DestinationImageFile:"$DossierExport\Sources\install.wim" /DestinationName:$Item | Out-Null
          }
        }
      }
    }
    Dismount-DiskImage -ImagePath $PatchISO | Out-Null
  }
}

# --------------------------- GUI (DPI-safe + Fancy buttons + ListView log) ---------------------------
[System.Windows.Forms.Application]::EnableVisualStyles()
Assert-Admin

$Form = New-Object System.Windows.Forms.Form
$Form.Text = 'Build Windows 11 MUI — MultiIndex (GUI Pro)'
$Form.Size = [System.Drawing.Size]::new(980,700)
$Form.MinimumSize = [System.Drawing.Size]::new(960,660)
$Form.StartPosition = 'CenterScreen'
$Form.Font = New-Object System.Drawing.Font('Segoe UI',9)
$Form.BackColor = [System.Drawing.Color]::FromArgb(250,250,251)
$Form.AutoScaleMode = 'Dpi'
$Form.KeyPreview = $true

# --- helpers boutons ---
function Set-RoundedRegion {
  param([System.Windows.Forms.Button]$Button,[int]$Radius=6)
  $gp   = New-Object System.Drawing.Drawing2D.GraphicsPath
  $rect = New-Object System.Drawing.Rectangle(0,0,$Button.Width,$Button.Height)
  $d = $Radius * 2
  $gp.AddArc(0,0,$d,$d,180,90) | Out-Null
  $gp.AddArc($rect.Width-$d,0,$d,$d,270,90) | Out-Null
  $gp.AddArc($rect.Width-$d,$rect.Height-$d,$d,$d,0,90) | Out-Null
  $gp.AddArc(0,$rect.Height-$d,$d,$d,90,90) | Out-Null
  $gp.CloseFigure()
  $Button.Region = New-Object System.Drawing.Region($gp)
  $gp.Dispose()
}
function New-FancyButton {
  param([string]$Text,[ValidateSet('primary','secondary')][string]$Kind='secondary')
  $b = New-Object System.Windows.Forms.Button
  $b.Text  = $Text; $b.Width = 140; $b.Height = 34
  $b.FlatStyle = 'Flat'; $b.FlatAppearance.BorderSize = 0
  $b.UseVisualStyleBackColor = $false; $b.Margin = '6,2,6,2'
  if ($Kind -eq 'primary') {
    $b.BackColor = [System.Drawing.Color]::FromArgb(40,132,244); $b.ForeColor = [System.Drawing.Color]::White
  } else {
    $b.BackColor = [System.Drawing.Color]::FromArgb(240,243,247); $b.ForeColor = [System.Drawing.Color]::FromArgb(32,32,32)
    $b.FlatAppearance.BorderSize  = 1; $b.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(208,213,220)
  }
  $b.Tag = $Kind
  $b.Add_MouseEnter({ if ($this.Tag -eq 'primary') { $this.BackColor = [System.Drawing.Color]::FromArgb(30,120,235) } else { $this.BackColor = [System.Drawing.Color]::FromArgb(233,237,242) } })
  $b.Add_MouseLeave({ if ($this.Tag -eq 'primary') { $this.BackColor = [System.Drawing.Color]::FromArgb(40,132,244) } else { $this.BackColor = [System.Drawing.Color]::FromArgb(240,243,247) } })
  $b.Add_Resize({ param($s,$e) Set-RoundedRegion -Button $s -Radius 6 })
  return $b
}

# --- Group: Paths (DPI safe) ---
$grpPaths = New-Object System.Windows.Forms.GroupBox -Property @{
  Text='Paths'; Location=[System.Drawing.Point]::new(10,10); Size=[System.Drawing.Size]::new(950,120); Anchor='Top,Left,Right'
}
$tlpPaths = New-Object System.Windows.Forms.TableLayoutPanel -Property @{
  ColumnCount = 2; RowCount = 2; Dock='Fill'; Padding='10,10,10,10'
}
$tlpPaths.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::AutoSize)) | Out-Null
$tlpPaths.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent,100)) | Out-Null
$tlpPaths.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::AutoSize)) | Out-Null
$tlpPaths.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::AutoSize)) | Out-Null
$lblRoot = New-Object System.Windows.Forms.Label -Property @{ Text='Project root folder'; AutoSize=$true; Anchor='Left' }
$tbRoot  = New-Object System.Windows.Forms.TextBox -Property @{ Dock='Fill' }
$lblLocal= New-Object System.Windows.Forms.Label -Property @{ Text='Local work root'; AutoSize=$true; Anchor='Left' }
$tbLocal = New-Object System.Windows.Forms.TextBox -Property @{ Dock='Fill' }
$tlpPaths.Controls.Add($lblRoot,0,0);  $tlpPaths.Controls.Add($tbRoot,1,0)
$tlpPaths.Controls.Add($lblLocal,0,1); $tlpPaths.Controls.Add($tbLocal,1,1)
$grpPaths.Controls.Add($tlpPaths)

# --- Group: Options ---
$grpOpts = New-Object System.Windows.Forms.GroupBox -Property @{
  Text='Options'; Location=[System.Drawing.Point]::new(10,$grpPaths.Bottom+10); Size=[System.Drawing.Size]::new(950,90); Anchor='Top,Left,Right'
}
$lblType = New-Object System.Windows.Forms.Label -Property @{ Text='Type'; Location=[System.Drawing.Point]::new(14,25); AutoSize=$true }
$cboType = New-Object System.Windows.Forms.ComboBox -Property @{ DropDownStyle='DropDownList'; Location=[System.Drawing.Point]::new(14,45); Width=120; Enabled=$false }
$cboType.Items.AddRange(@('Client','Server')) | Out-Null
$lblEdition = New-Object System.Windows.Forms.Label -Property @{ Text='Edition (IndexName)'; Location=[System.Drawing.Point]::new(150,25); AutoSize=$true }
$cboEdition = New-Object System.Windows.Forms.ComboBox -Property @{ Location=[System.Drawing.Point]::new(150,45); Width=260; Enabled=$false }
$cboEdition.Items.AddRange(@('Windows 11 Education','Windows 11 Enterprise','Windows 11 Pro','Windows 11 Pro Education','Windows 11 Pro for Workstations')) | Out-Null
$lblLang = New-Object System.Windows.Forms.Label -Property @{ Text='Base language'; Location=[System.Drawing.Point]::new(430,25); AutoSize=$true }
$cboLang = New-Object System.Windows.Forms.ComboBox -Property @{ Location=[System.Drawing.Point]::new(430,45); Width=180; DropDownStyle='DropDownList'; Enabled=$false }
$grpOpts.Controls.AddRange(@($lblType,$cboType,$lblEdition,$cboEdition,$lblLang,$cboLang))

# --- Group: Steps ---
$grpSteps = New-Object System.Windows.Forms.GroupBox -Property @{
  Text='Steps'; Location=[System.Drawing.Point]::new(10,$grpOpts.Bottom+10); Size=[System.Drawing.Size]::new(950,70); Anchor='Top,Left,Right'
}
$chk1 = New-Object System.Windows.Forms.CheckBox -Property @{ Text='Step 1: Copy installation files'; Location=[System.Drawing.Point]::new(14,30); Checked=$true; AutoSize=$true }
$chk2 = New-Object System.Windows.Forms.CheckBox -Property @{ Text='Step 2: Add WinPE languages'; Location=[System.Drawing.Point]::new(260,30); Checked=$true; AutoSize=$true }
$chk3 = New-Object System.Windows.Forms.CheckBox -Property @{ Text='Step 3: Distribution languages'; Location=[System.Drawing.Point]::new(500,30); Checked=$true; AutoSize=$true }
$chk4 = New-Object System.Windows.Forms.CheckBox -Property @{ Text='Step 4: NetFX3 + lang.ini'; Location=[System.Drawing.Point]::new(750,30); Checked=$true; AutoSize=$true }
$grpSteps.Controls.AddRange(@($chk1,$chk2,$chk3,$chk4))

# --- Group: Actions ---
$grpActions = New-Object System.Windows.Forms.GroupBox -Property @{
  Text='Actions'; Location=[System.Drawing.Point]::new(10,$grpSteps.Bottom+10); Size=[System.Drawing.Size]::new(950,70); Anchor='Top,Left,Right'
}
$flow = New-Object System.Windows.Forms.FlowLayoutPanel -Property @{
  Dock='Fill'; FlowDirection='LeftToRight'; WrapContents=$false; AutoSize=$false; Padding='4,6,4,6'
}
$btnCheck = New-FancyButton 'Check ISO' 'secondary'
$btnBuild = New-FancyButton 'Run Build' 'primary'
$btnTest  = New-FancyButton 'Test folders' 'secondary'
$btnSave  = New-FancyButton 'Save Config' 'secondary'
$btnLoad  = New-FancyButton 'Load Config' 'secondary'
$flow.Controls.AddRange(@($btnCheck,$btnBuild,$btnTest,$btnSave,$btnLoad))
$grpActions.Controls.Add($flow)

# --- Log ListView + status ---
$LogBox = New-Object System.Windows.Forms.ListView -Property @{
  View='Details'; FullRowSelect=$true; GridLines=$false; HideSelection=$false
  Location=[System.Drawing.Point]::new(10,$grpActions.Bottom+10)
  Size=[System.Drawing.Size]::new(950,250); Anchor='Top,Left,Right'
  HeaderStyle='Nonclickable'; Font=(New-Object System.Drawing.Font('Segoe UI',9))
}
$global:LogBox = $LogBox   # <<< IMPORTANT pour Write-Log

# hauteur de ligne (imagelist)
$img = New-Object System.Windows.Forms.ImageList
$img.ImageSize = [Drawing.Size]::new(1,20)
$LogBox.SmallImageList = $img

[void]$LogBox.Columns.Add('Time',140)
[void]$LogBox.Columns.Add('Level',70)
[void]$LogBox.Columns.Add('Message',650)
$LogBox.Add_Resize({
  $pad = 6
  $msgWidth = $LogBox.ClientSize.Width - ($LogBox.Columns[0].Width + $LogBox.Columns[1].Width + $pad)
  if ($msgWidth -lt 150) { $msgWidth = 150 }
  $LogBox.Columns[2].Width = $msgWidth
})

# Menu contextuel: Copy / Clear
$cm = New-Object System.Windows.Forms.ContextMenuStrip
$miCopy  = $cm.Items.Add('Copy selected')
$miClear = $cm.Items.Add('Clear')
$miCopy.Add_Click({
  if ($LogBox.SelectedItems.Count -gt 0) {
    $txt = $LogBox.SelectedItems | ForEach-Object { "{0} {1}  {2}" -f $_.SubItems[0].Text,$_.SubItems[1].Text,$_.SubItems[2].Text } | Out-String
    [System.Windows.Forms.Clipboard]::SetText($txt.TrimEnd())
  }
})
$miClear.Add_Click({ $LogBox.Items.Clear() })
$LogBox.ContextMenuStrip = $cm

$status = New-Object System.Windows.Forms.StatusStrip -Property @{ SizingGrip=$false }
$global:StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel -Property @{ Text='Ready'; Spring=$true }
[void]$status.Items.Add($global:StatusLabel)
$status.Dock = 'Bottom'
$status.BringToFront()

# add to form
$Form.Controls.AddRange(@($grpPaths,$grpOpts,$grpSteps,$grpActions,$LogBox,$status))
$Form.AcceptButton = $btnBuild

# ajuster la hauteur du log pour ne pas chevaucher la statusbar
function Update-LogArea {
  $margin = 8
  $newH = $Form.ClientSize.Height - $LogBox.Top - $status.Height - $margin
  if ($newH -lt 80) { $newH = 80 }
  $LogBox.Height = $newH
}
$Form.Add_Shown({ Update-LogArea })
$Form.Add_Resize({ Update-LogArea })
$Form.Add_Layout({ Update-LogArea })

# --------------------------- Defaults / default.json ---------------------------
$cboType.SelectedItem = 'Client'
$cboEdition.Text      = 'Windows 11 Pro'
$tbRoot.Text          = ''
$tbLocal.Text         = ''

$DefaultJson = Join-Path $PSScriptRoot 'default.json'
if (Test-Path -LiteralPath $DefaultJson) {
  try {
    $cfg = Get-Content -LiteralPath $DefaultJson -Raw | ConvertFrom-Json
    if ($cfg.ProjectRoot) { $tbRoot.Text  = $cfg.ProjectRoot }
    if ($cfg.LocalRoot)   { $tbLocal.Text = $cfg.LocalRoot }
    if ($cfg.ServerClient){ $cboType.Tag    = $cfg.ServerClient }     # applied after Check ISO
    if ($cfg.OsName)      { $cboEdition.Tag = $cfg.OsName }           # applied after Check ISO
    if ($cfg.BaseLangue)  { $cboLang.Tag    = $cfg.BaseLangue }       # applied after Check ISO
    if ($cfg.Step1_CopyInstall -ne $null) { $chk1.Checked = [bool]$cfg.Step1_CopyInstall }
    if ($cfg.Step2_WinPELang   -ne $null) { $chk2.Checked = [bool]$cfg.Step2_WinPELang }
    if ($cfg.Step3_DistLang    -ne $null) { $chk3.Checked = [bool]$cfg.Step3_DistLang }
    if ($cfg.Step4_ModifyImg   -ne $null) { $chk4.Checked = [bool]$cfg.Step4_ModifyImg }
    Write-Log 'default.json loaded.'
  } catch { Write-Log "Failed to read default.json: $_" 'WARN' }
}

function Get-Paths {
  Ensure-ProjectSubfolders $tbRoot.Text
  Ensure-LocalSubfolders  $tbLocal.Text
  return [ordered]@{
    ISO          = Join-Path $tbRoot.Text 'ISO'
    WinPE_OCs    = Join-Path $tbRoot.Text 'WinPE_OCs'
    Export       = Join-Path $tbRoot.Text 'Export'
    SXS          = Join-Path $tbRoot.Text 'SXS'
    MountWinPE   = Join-Path $tbLocal.Text 'MountWinPE'
    MountWinRE   = Join-Path $tbLocal.Text 'MountWinRE'
    MountInstall = Join-Path $tbLocal.Text 'MountInstall'
    scratch      = Join-Path $tbLocal.Text 'scratch'
    distribution = Join-Path $tbLocal.Text 'distribution'
  }
}

function Get-Settings {
  $serverClient = 'Client'
  if ($cboType.Enabled -and $cboType.SelectedItem) { $serverClient = [string]$cboType.SelectedItem }

  $osName = 'Windows 11 Pro'
  if ($cboEdition.Enabled -and $cboEdition.Text) { $osName = [string]$cboEdition.Text }

  $baseLang = ''
  if ($cboLang.Enabled -and $cboLang.SelectedItem -and $cboLang.SelectedItem -ne 'Select') { $baseLang = [string]$cboLang.SelectedItem }

  [ordered]@{
    ProjectRoot  = $tbRoot.Text
    LocalRoot    = $tbLocal.Text
    ServerClient = $serverClient
    OsName       = $osName
    BaseLangue   = $baseLang
    Step1_CopyInstall = $chk1.Checked
    Step2_WinPELang   = $chk2.Checked
    Step3_DistLang    = $chk3.Checked
    Step4_ModifyImg   = $chk4.Checked
  }
}

# --------------------------- Actions ---------------------------
$btnTest.Add_Click({
  try {
    $p = Get-Paths
    Write-Log "Project: $($tbRoot.Text)"
    Write-Log "Local:   $($tbLocal.Text)"
    foreach($v in $p.GetEnumerator()){ Write-Log ("{0}: {1}" -f $v.Key, $v.Value) }
  } catch { Write-Log "ERROR test: $_" 'ERROR' }
})

$btnSave.Add_Click({
  try {
    $json = (Get-Settings | ConvertTo-Json -Depth 5)
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = 'JSON (*.json)|*.json'
    $sfd.FileName = 'config.json'
    if ($sfd.ShowDialog() -eq 'OK') { $json | Out-File -LiteralPath $sfd.FileName -Encoding UTF8; Write-Log "Config saved: $($sfd.FileName)" }
  } catch { Write-Log "ERROR Save Config: $_" 'ERROR' }
})

$btnLoad.Add_Click({
  try {
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = 'JSON (*.json)|*.json'
    if ($ofd.ShowDialog() -ne 'OK') { return }
    $cfg = Get-Content -LiteralPath $ofd.FileName -Raw | ConvertFrom-Json
    if ($cfg.ProjectRoot) { $tbRoot.Text  = $cfg.ProjectRoot }
    if ($cfg.LocalRoot)   { $tbLocal.Text = $cfg.LocalRoot }
    if ($cfg.ServerClient){ $cboType.Tag    = $cfg.ServerClient }
    if ($cfg.OsName)      { $cboEdition.Tag = $cfg.OsName }
    if ($cfg.BaseLangue)  { $cboLang.Tag    = $cfg.BaseLangue }
    if ($cfg.Step1_CopyInstall -ne $null) { $chk1.Checked = [bool]$cfg.Step1_CopyInstall }
    if ($cfg.Step2_WinPELang   -ne $null) { $chk2.Checked = [bool]$cfg.Step2_WinPELang }
    if ($cfg.Step3_DistLang    -ne $null) { $chk3.Checked = [bool]$cfg.Step3_DistLang }
    if ($cfg.Step4_ModifyImg   -ne $null) { $chk4.Checked = [bool]$cfg.Step4_ModifyImg }
    Write-Log "Config loaded: $($ofd.FileName)"
  } catch { Write-Log "ERROR Load Config: $_" 'ERROR' }
})

# Check ISO: populate Base language and enable Options
$btnCheck.Add_Click({
  try {
    $p = Get-Paths
    $isoDir = $p.ISO
    if (-not (Test-Path -LiteralPath $isoDir)) { [System.Windows.Forms.MessageBox]::Show("ISO folder not found:`n$isoDir","ISO Languages","OK","Warning") | Out-Null; return }
    $isos = Get-ChildItem -LiteralPath $isoDir -Filter *.iso -ErrorAction SilentlyContinue
    if (-not $isos) { [System.Windows.Forms.MessageBox]::Show("No ISO found in:`n$isoDir","ISO Languages","OK","Information") | Out-Null; return }

    $LanguageCode = 'bg-bg','cs-cz','da-dk','de-de','el-gr','en-gb','en-us','es-es','es-mx','et-ee','fi-fi','fr-ca','fr-fr','hr-hr','hu-hu','it-it','ja-jp','ko-kr','lt-lt','lv-lv','nb-no','nl-nl','pl-pl','pt-br','pt-pt','ro-ro','ru-ru','sk-sk','sl-si','sv-se','tr-tr','uk-ua','zh-cn','zh-tw'
    $set = [System.Collections.Generic.HashSet[string]]::new()

    foreach($iso in $isos){
      try {
        $vol = Mount-DiskImage -ImagePath $iso.FullName -PassThru | Get-DiskImage | Get-Volume | Select-Object -First 1
        if (-not $vol) { continue }
        foreach($lc in $LanguageCode){
          $langPath = ('{0}:\\sources\\{1}' -f $vol.DriveLetter, $lc)
          if (Test-Path -LiteralPath $langPath) { [void]$set.Add($lc) }
        }
      } finally { Dismount-DiskImage -ImagePath $iso.FullName -ErrorAction SilentlyContinue | Out-Null }
    }

    if ($set.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show('No language folders were found in any ISO.','ISO Languages','OK','Information') | Out-Null; return }

    $langs = @($set) | Sort-Object
    Write-Log ("Languages found: {0}" -f ($langs -join ', '))

    $cboLang.Items.Clear(); [void]$cboLang.Items.Add('Select')
    foreach($l in $langs){ [void]$cboLang.Items.Add($l) }

    $cboLang.Enabled    = $true
    $cboType.Enabled    = $true
    $cboEdition.Enabled = $true

    if ($cboLang.Tag -and $cboLang.Items.Contains($cboLang.Tag))       { $cboLang.SelectedItem    = $cboLang.Tag } else { $cboLang.SelectedIndex = 0 }
    if ($cboType.Tag -and $cboType.Items.Contains($cboType.Tag))       { $cboType.SelectedItem    = $cboType.Tag } else { if (-not $cboType.SelectedItem)    { $cboType.SelectedItem = 'Client' } }
    if ($cboEdition.Tag -and $cboEdition.Items.Contains($cboEdition.Tag)) { $cboEdition.SelectedItem = $cboEdition.Tag } else { if (-not $cboEdition.Text) { $cboEdition.Text = 'Windows 11 Pro' } }
  } catch {
    Write-Log "ERROR Check ISO: $_" 'ERROR'
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Error','OK','Error') | Out-Null
  }
})

$btnBuild.Add_Click({
  try {
    if (-not $cboLang.Enabled -or -not $cboLang.SelectedItem -or $cboLang.SelectedItem -eq 'Select') {
      [System.Windows.Forms.MessageBox]::Show('Please click "Check ISO" and choose a Base language before building.','Missing Base language','OK','Warning') | Out-Null
      return
    }

    $p = Get-Paths

    $ServerClient = 'Client'
    if ($cboType.Enabled -and $cboType.SelectedItem) { $ServerClient = [string]$cboType.SelectedItem }
    if ($ServerClient -eq 'Serveur') { $ServerClient = 'Server' }

    $OsName = 'Windows 11 Pro'
    if ($cboEdition.Enabled -and $cboEdition.Text) { $OsName = [string]$cboEdition.Text }

    $BaseLangue = [string]$cboLang.SelectedItem

    Write-Log '--- Build started (derived paths) ---'

    CleanupSafe -DossierMountWindows $p.MountInstall -DossierMountWinPE $p.MountWinPE -DossierMountWinRE $p.MountWinRE -DossierMountScratch $p.scratch -DossierTravail $p.distribution
    Prepare    -DossierMountWindows $p.MountInstall -DossierMountWinPE $p.MountWinPE -DossierMountWinRE $p.MountWinRE -DossierMountScratch $p.scratch -DossierTravail $p.distribution

    if ($chk1.Checked) { CopierFichierInstallation -LangueBase $BaseLangue -DossierExport $p.Export -DossierAvecISO $p.ISO }
    if ($chk2.Checked) { AjoutLangueWinPE -DossierMountWinPE $p.MountWinPE -DossierAvecISO $p.ISO -OSclientOuServer $ServerClient -DossierLangueWinPE $p.WinPE_OCs -DossierExport $p.Export -LangueDeBase $BaseLangue }
    if ($chk3.Checked) { AjoutLangueDistribution -DossierExport $p.Export -DossierAvecISO $p.ISO }

    if ($chk4.Checked) {
      Wimindex       -DossierAvecISO $p.ISO -DossierExport $p.Export -DossierTravail $p.distribution -IndexName $OsName
      CopierSXS      -DossierExportsxs $p.SXS -DossierAvecISO $p.ISO
      ActivateNetFX3 -DossierMountWindows $p.MountInstall -DossierExport $p.Export -DossierExportsxs $p.SXS -IndexName 'ALL'
      FakeLangIni    -DossierExport $p.Export -DossierAvecISO $p.ISO -Languebase $BaseLangue
    }

    CleanupSafe -DossierMountWindows $p.MountInstall -DossierMountWinPE $p.MountWinPE -DossierMountWinRE $p.MountWinRE -DossierMountScratch $p.scratch -DossierTravail $p.distribution

    Write-Log '--- Build finished successfully ---'

    # Popup de fin + son
    [System.Media.SystemSounds]::Asterisk.Play()
    [System.Windows.Forms.MessageBox]::Show(
      $Form,
      "Build finished successfully.`n`nExport folder:`n$($p.Export)",
      'Build MUI — Completed',
      [System.Windows.Forms.MessageBoxButtons]::OK,
      [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null

  } catch {
    Write-Log "ERROR build: $_" 'ERROR'
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Error','OK','Error') | Out-Null
  }
})

# Show UI
[void]$Form.ShowDialog()
