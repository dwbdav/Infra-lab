#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.2.12.1
 Author:         Jan Buelens, Landesk Software (idea stolen from Sergio Ribeiro)

 Script Function:
	CopyDrivers. This script copies machine dependent drivers to a provisioning / OSD client machine.
	A mapping table (CopyDrivers.ini) is used to map the WMI machine model to a driver source folder.
	
	A GUI is included to build CopyDrivers.ini
	
	Version: 1.5.1

#ce ----------------------------------------------------------------------------

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>

Dim $iniFilename = ""
Dim $Manufacturer = ""
Dim $Model = ""
Dim $Version = ""
Dim $subfolder = ""
Dim $SourceFolder = ""
Dim $TargetFolder = ""
Dim $sysprep = "C:\sysprep\sysprep.inf"

Dim $bVerbose = False
Dim $bRunOnce = True
Dim $bCmdLines = True

; ===========================================================================================
; Validate command line parameters and verify that copydrivers.ini exists
; ===========================================================================================

If $CmdLine[0] = 0 Then DoGui()		; no command line parameters - do gui

If $CmdLine[0] > 0 And ($CmdLine[1] = "/?" Or $CmdLine[1] = "-?" Or $CmdLine[1] = "help") Then
	Usage()
EndIf

For $n = 1 to $CmdLine[0]
	if $CmdLine[$n] = "/s" Or $CmdLine[$n] = "-s"  Then
		if $n >= $CmdLine[0] Then Usage()
		$SourceFolder = $CmdLine[$n + 1]
		$n = $n + 1
	ElseIf $CmdLine[$n] = "/d" Or $CmdLine[$n] = "-d"  Then
		if $n >= $CmdLine[0] Then Usage()
		$TargetFolder = $CmdLine[$n + 1]
		$n = $n + 1
	ElseIf $CmdLine[$n] = "/c" Or $CmdLine[$n] = "-c"  Then
		; if no other command line parameters are required, use /c to copy drivers rather than launch GUI
	ElseIf $CmdLine[$n] = "/v" Or $CmdLine[$n] = "-v"  Then
		$bVerbose = True;
	;If there is a reason for not doing the cmdlines and GuiRunOnce stuff, uncomment these lines
	; ElseIf $CmdLine[$n] = "/cmdlines" Or $CmdLine[$n] = "-cmdlines"  Then
	;	$bCmdLines = False
	; ElseIf $CmdLine[$n] = "/RunOnce" Or $CmdLine[$n] = "-RunOnce"  Then
	;	$bRunOnce = False
	Else
		Usage()
	EndIf
Next

$iniFilename = @ScriptDir & "\copydrivers.ini"	; @ScriptDir is folder in which this script (or compiled program) resides
If not FileExists($iniFilename) Then ErrorExit("File not found: " & $iniFilename, 2)

; If no source and target folders were defined on the command line, take them from the [Config] section of copydrivers.ini

If $SourceFolder = "" Then $SourceFolder = IniRead($iniFilename, "Config", "DriversSource", "")
If $TargetFolder = "" Then $TargetFolder = IniRead($iniFilename, "Config", "DriversTarget", "")
If $SourceFolder = "" Then ErrorExit("No Drivers Source Folder defined", 3)
If $TargetFolder = "" Then ErrorExit("No Drivers Target Folder defined", 4)

; MsgBox(0, "CopyDrivers", "source: " & $SourceFolder & @CRLF & "target: " & $TargetFolder);

; ===========================================================================================
; Read Manufacturer, Model and Version from WMI. We only use Model.
; ===========================================================================================

ReadWmi($Manufacturer, $Model, $Version)

; ===========================================================================================
; Find a match for WMI Model in [Models] section of copydrivers.ini
; ===========================================================================================

;IniReadSection returns a 2 dimensional array of keywords and values; $ini[n][0] is key # n, $ini[n][1] is value # n; $ini[0][0] is the number of elements
$ini = IniReadSection($iniFilename, "Models")
if @error OR $ini[0][0] = 0 Then ErrorExit("There is no [Models] section in " & $iniFilename, 5)

; Take WMI Model and find match in ini file
For $n = 1 to $ini[0][0]
	if $ini[$n][0] = $Model Then
		$subfolder = $ini[$n][1]
		ExitLoop
	EndIf
Next

if $subfolder = "" Then ErrorExit("No match found for Model """ & $Model & """ in " &$iniFilename, 6)

If $bVerbose Then MsgBox(0, "CopyDrivers","Manufacturer: " & $Manufacturer & @CRLF & "Model: " & $Model  & @CRLF & "Version: " & $Version  & @CRLF & "subfolder: " & $subfolder)

; ===========================================================================================
; Copy the driver files
; ===========================================================================================

$src = $SourceFolder & "\" & $subfolder
If Not IsFolder($src) Then ErrorExit("Source folder not found: " & $src, 7)
DirCreate($TargetFolder)
If Not IsFolder($TargetFolder) Then ErrorExit("Unable to create target folder: " & $TargetFolder, 8)
If Not DirCopy($src, $TargetFolder, 1) Then ErrorExit("Unable to copy folder: " & $TargetFolder, 9)	; 1 on DirCopy means overwrite existing files

; ===========================================================================================
; Handle RunOnce and CmdLines
; ===========================================================================================

if $bRunOnce Then DoRunOnce()
if $bCmdLines Then DoCmdLines()

; ===========================================================================================
; Done
; ===========================================================================================

; ===========================================================================================
Func DoCmdLines()
; Run at deployment time if the $bCmdLines is true. If there is a cmdlines.txt file in the drivers folder that we just copied, set up 
; sysprep.inf such that it will be processed at mini-setup time. If sysprep.inf already refers to a cmdlines.txt file, merge it. The cmdlines.txt file must be
; in the format as described in the sysprep documentation. Example:
;
;  [cmdlines]
;  "c:\drivers\setup\driver1\setup.exe"
;
; This program also has a GUI that allows cmdlines.txt to be edited in a convenient way, without the user being aware of the format or the location of the file.
; ===========================================================================================

Dim $MyBase = $TargetFolder
Dim $MyCmdLines = $MyBase & "\cmdlines.txt"
Dim $oemFolder = ""
Dim $OemCmdLines = ""

if not FileExists($MyCmdLines) Then Return
	
if not FileExists($sysprep) Then ErrorExit("File not found: " & $sysprep, 2)
$InstallFilesPath = Iniread($sysprep, "unattended", "InstallFilesPath", "")
if $InstallFilesPath = "" Then
	; no InstallFilesPath in sysprep.inf - create one
	$InstallFilesPath = $MyBase
	IniWrite($sysprep, "unattended", "InstallFilesPath", $InstallFilesPath)
EndIf

$oemFolder = $InstallFilesPath & "\$oem$"
$OemCmdLines = $oemFolder & "\cmdlines.txt"

if not FileExists($OemCmdLines) Then
	; no $oem$\cmdlines.txt exist - just copy ours
	$success = FileCopy($MyCmdLines, $OemCmdLines, 8)	; 8 = create folders
	if $success = 0 Then ErrorExit("Copy " & $MyCmdLines & " to " & $OemCmdLines & " failed", 3)
	Exit 0
EndIf

; A $oem$\cmdlines.txt already exists - append ours
$file1 = FileOpen($MyCmdLines, 0)	; 0 = read
if $file1 = -1 Then ErrorExit("Error opening " & $MyCmdLines, 5)
$file2 = FileOpen($OemCmdLines, 1)	; 1 = append
if $file2 = -1 Then ErrorExit("Error opening " & $OemCmdLines, 4)
While 1
    $line = FileReadLine($file1)
    If @error Then ExitLoop
	If StringStripWS($line,8) <> "[commands]" Then		; StringStripWS($line,8) strips all white space
		FileWriteLine($file2, $line)
	EndIf
Wend
FileClose($file1)
FileClose($file2)

EndFunc


; ===========================================================================================
Func DoRunOnce()
; Run at deployment time if the $bRunonce is true. If there is a file called GuiRunOnce.ini in the drivers 
; folder that we just copied, merge its GuiRunOnce section with the sysprep.inf GuiRunOnce section. The GuiRunOnce.ini file must be
; in the format as described in the sysprep documentation. Example:
;
;  [GuiRunOnce]
;  Command0="c:\drivers\driver1\setup.exe"
;  Command1="c:\drivers\driver2\setup.exe"
;
; This program also has a GUI that allows GuiRunOnce.ini to be edited in a convenient way, without the user to be aware of the format or the location of the file.
; ===========================================================================================


Dim $MyRunOnce = $TargetFolder & "\GuiRunOnce.ini"

if not FileExists($MyRunOnce) Then Return

if not FileExists($sysprep) Then ErrorExit("File not found: " & $sysprep, 2)
Dim $section1[1][1]
$section1[0][0] = 0
$section1 = IniReadSection($sysprep, "GuiRunOnce")
if @error Then
	Dim $section1[1][1]
	$section1[0][0] = 0
EndIf
$section2 = IniReadSection($MyRunOnce, "GuiRunOnce")
if @error Then Return
if $section2[0][0] = 0 Then Return

$count = $section1[0][0]
For $i = 1 To $section2[0][0]
	$count = $count + 1
	ReDim $section1[$count + 1][2]
	$section1[$count][0] = $section2[$i][0]
	$section1[$count][1] = $section2[$i][1]
Next
$section1[0][0] = $count
For $i = 1 To $section1[0][0]
	$section1[$count][0] = "Command" & ($i - 1)
Next

IniWriteSection($sysprep, "GuiRunOnce", $section1)


EndFunc

; ===========================================================================================
; Set the 3 WMI attributes mentioned. We only use the Model, but feel free to organise things differently
Func ReadWmi(ByRef $Manufacturer, ByRef $Model, ByRef $Version)
; ===========================================================================================

$objWMIService = ObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
If $objWMIService = 0 Then ErrorExit("Failed to connect to WMI", 10)

$colRows = $objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystem")
For $row In $colRows
	$Manufacturer = StringStripWS($Row.Manufacturer, 3)
	$Model = StringStripWS($Row.Model, 3)
Next

$colRows = $objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystemProduct")
For $row In $colRows
	$Version = StringStripWS($Row.Version, 3)
Next

Return True

EndFunc



; ===========================================================================================
Func Usage()
; ===========================================================================================

	Msgbox ("0", "CopyDrivers V1.5.1", _
	                            "This program copies machine specific drivers from a source folder on a" _
	                  & @CRLF & "server to a destination folder on the local machine." & @CRLF _
	                  & @CRLF & "Usage: CopyDrivers [/s <sourcedir>] [/d <destdir>] [/cmdlines] [/RunOnce] [/c] [/v]" _
	                  & @CRLF & "where <sourcedir> is the base path for machine specfic driver folders" _
	                  & @CRLF & "           <destdir> is the target folder on the local machine." _
					  & @CRLF & "           /v: verbose" _
					  & @CRLF & "           /c: copy" & @CRLF _
					  & @CRLF & "CopyDrivers requires a list that associates machine types with driver folders." _
					  & @CRLF & "This list is to be supplied in the [Models] section of copydrivers.ini, which" _
					  & @CRLF & "associates WMI model names with specific subfolders of <sourcedir>." & @CRLF _
					  & @CRLF & "When invoked without command line switches, CopyDrivers opens a GUI that allows" _
					  & @CRLF & "copydrivers.ini to be edited. Use /c to do the copying rather than show the GUI." _
					  )

	Exit 1

EndFunc


; ===========================================================================================
; The remainder of the file is just GUI stuff. It does nothing that you can't do by simply editing the CopyDrivers.ini file
; ===========================================================================================


; ===========================================================================================
; Main GUI function called when program is invoked with no command line parameters
Func DoGui()
; ===========================================================================================
$iniFilename = @ScriptDir & "\copydrivers.ini"	; @ScriptDir is folder in which this script (or compiled program) resides
$SourceFolder = IniRead($iniFilename, "Config", "DriversSource", "")
$TargetFolder = IniRead($iniFilename, "Config", "DriversTarget", "")

#Region ### START Koda GUI section ### Form=z:\install\autoit\koda_1.7.0.1\forms\myform1.kxf
$Form_Main = GUICreate("CopyDrivers", 452, 322)
$BtnOK = GUICtrlCreateButton("OK", 16, 280, 97, 25, 0)
$EditSource = GUICtrlCreateInput("", 13, 32, 305, 21)
GUICtrlSetState(-1, $GUI_DISABLE)
$BtnConfig = GUICtrlCreateButton("Edit", 335, 32, 57, 21, 0)
$ListView1 = GUICtrlCreateListView("WMI Model|Subfolder", 13, 120, 305, 145)
GUICtrlSendMsg(-1, 0x101E, 0, 150)
GUICtrlSendMsg(-1, 0x101E, 1, 150)
; GUICtrlSetTip(-1, "abc")
$BtnAdd = GUICtrlCreateButton("Add", 335, 126, 57, 21, 0)
$BtnEdit = GUICtrlCreateButton("Edit", 335, 157, 57, 21, 0)
$BtnDelete = GUICtrlCreateButton("Delete", 335, 190, 57, 21, 0)
GUICtrlCreateLabel("Drivers source folder", 16, 14, 101, 17)
$BtnCancel = GUICtrlCreateButton("Cancel", 133, 281, 97, 25, 0)
$EditTarget = GUICtrlCreateInput("", 13, 79, 305, 21)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlCreateLabel("Drivers target folder", 16, 61, 96, 17)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

GUICtrlSetData($EditSource, $SourceFolder)
GUICtrlSetData($EditTarget, $TargetFolder)

;IniReadSection returns a 2 dimensional array of keywords and values; $ini[n][0] is key # n, $ini[n][1] is value # n; $ini[0][0] is the number of elements
$items = 0
$count = 0
$ini = IniReadSection($iniFilename, "Models")
if not @error Then
	$items = $ini[0][0]
EndIf

$count1 = $items
if ($items = 0) Then $count1 = 1

Dim $item [$count1] [4]	; we'll store the model in item[n][0], the folder in item[n][1], the listview controlid in item[n][2] and the state (0 = deleted, 1 = active) in item[n][3]
if $items = 0 Then
	; if the section was empty or non-existing, we create one dummy item to avoid run-time errors
	$item[0][0] = ""
	$item[0][1] = ""
	$item[0][2] = 0
	$item[0][3] = 0
EndIf

For $n = 1 to $items
	$item[$n-1][0] = $ini[$n][0]
	$item[$n-1][1] = $ini[$n][1]
	$item[$n-1][2] = GUICtrlCreateListViewItem($ini[$n][0] & "|" & $ini[$n][1], $ListView1)
	$item[$n-1][3] = 1
	$count = $count + 1
Next

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $BtnOK
			IniWrite($iniFilename, "Config", "DriversSource", $SourceFolder)
			IniWrite($iniFilename, "Config", "DriversTarget", $TargetFolder)
			Dim $ini[$count][2]
			$i = 0
			for $n = 0 to UBound($item) - 1
				if $item[$n][3] = 1 Then
					$ini[$i][0] = $item[$n][0]
					$ini[$i][1] = $item[$n][1]
					$i = $i + 1
				EndIf
			Next
			IniWriteSection($iniFilename, "Models", $ini, 0)
			Exit
		Case $BtnCancel
			Exit
		Case $BtnConfig
			$newSource = $SourceFolder
			$newTarget = $TargetFolder
			if EditConfig($newSource, $newTarget) Then
				$SourceFolder = $newSource
				$TargetFolder = $newTarget
				GUICtrlSetData($EditSource, $SourceFolder)
				GUICtrlSetData($EditTarget, $TargetFolder)
			EndIf
		Case $BtnDelete
			$id = GUICtrlRead($ListView1)
			for $n = 0 to UBound($item) - 1
				if $item[$n][2] = $id And $item[$n][3] = 1 Then
					GUICtrlDelete($id)
					$item[$n][3] = 0
					$count = $count - 1
				EndIf
			Next
		Case $BtnAdd
			Dim $newModel = ""
			Dim $newFolder = ""
			If AddModel($newModel, $newFolder, 0) Then
				$n = UBound($item);
				ReDim $item[$n+1][4]
				$item[$n][0] = $newModel
				$item[$n][1] = $newFolder
				$item[$n][2] = GUICtrlCreateListViewItem($newModel & "|" & $newFolder, $ListView1)
				$item[$n][3] = 1
				$count = $count + 1
			EndIf
		Case $BtnEdit
			$id = GUICtrlRead($ListView1)
			for $n = 0 to UBound($item) - 1
				if $item[$n][2] = $id And $item[$n][3] = 1 Then
					ExitLoop
				EndIf
			Next
			if $n >= UBound($item) Then ContinueLoop
			Dim $newModel = $item[$n][0]
			Dim $newFolder = $item[$n][1]
			If AddModel($newModel, $newFolder, 1) Then
				$item[$n][0] = $newModel
				$item[$n][1] = $newFolder
				GUICtrlSetData($id, $newModel & "|" & $newFolder)
			EndIf
				
	EndSwitch
WEnd


EndFunc

; ===========================================================================================
; GUI function called when the Add or Edit button is pressed.
Func AddModel(ByRef $model, ByRef $folder, $flag)	; flag = 0: Add  flag = 1: Edit
; ===========================================================================================

$title = "Add Model"
if $flag = 1 Then $title = "Edit Model"

#Region ### START Koda GUI section ### Form=Z:\install\AutoIt\koda_1.7.0.1\Forms\Form_AddItem.kxf
$Form_AddModel = GUICreate($title, 429, 413)
GUICtrlCreateGroup("", 8, 1, 297, 137)
$InputModel = GUICtrlCreateInput("", 16, 40, 209, 21)
$InputFolder = GUICtrlCreateInput("", 16, 97, 209, 21, BitOR($ES_AUTOHSCROLL,$ES_READONLY) )
GUICtrlCreateLabel("Model", 16, 16, 33, 17)
GUICtrlCreateLabel("Subfolder", 17, 73, 49, 17)
$Btn_WMI = GUICtrlCreateButton("WMI", 236, 40, 57, 21, 0)
$BtnBrowse = GUICtrlCreateButton("..", 236, 97, 57, 21, 0)
$CmdLines = GUICtrlCreateEdit("", 16, 192, 385, 81, BitOR($ES_AUTOVSCROLL,$ES_AUTOHSCROLL,$ES_WANTRETURN,$WS_HSCROLL,$WS_VSCROLL,$WS_BORDER), $ES_MULTILINE)
$ButtonOK = GUICtrlCreateButton("&OK", 321, 11, 75, 25, 0)
$ButtonCancel = GUICtrlCreateButton("&Cancel", 322, 43, 75, 25, 0)
$RunOnce = GUICtrlCreateEdit("", 16, 304, 385, 81, BitOR($ES_AUTOVSCROLL,$ES_AUTOHSCROLL,$ES_WANTRETURN,$WS_HSCROLL,$WS_VSCROLL,$WS_BORDER), $ES_MULTILINE)
GUICtrlCreateGroup("Command lines for drivers that require a setup program", 8, 152, 409, 249)
GUICtrlCreateLabel("Before reboot (cmdlines.txt)", 16, 174, 132, 17)
GUICtrlCreateLabel("After reboot (GuiRunonce section of sysprep.inf)", 16, 287, 230, 17)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

GUICtrlSetData($InputModel, $model)
GUICtrlSetData($InputFolder, $folder)

; If the model specific folder exists, read the cmdlines.txt and GuiRunOnce.txt files from it and display their contents in the $cmdlines and $RunOnce edit boxes.
; If the model specific folder does not exist, disable the edit boxes

$RunOnceText = ""
$CmdLinesText = ""

$ModelFolder = $SourceFolder & "\" & $folder
if $SourceFolder = "" or $folder = "" Then $ModelFolder = "---dummy---"
if IsFolder($ModelFolder) Then
	$CmdLinesText = ReadCmdLines($ModelFolder)
	GUICtrlSetData($CmdLines, $CmdLinesText)
	$RunOnceText = ReadRunOnce($ModelFolder)
	GUICtrlSetData($RunOnce, $RunOnceText)
Else
	GUICtrlSetState($CmdLines, $GUI_DISABLE)
	GUICtrlSetState($RunOnce, $GUI_DISABLE)
EndIf

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
	Case $GUI_EVENT_CLOSE
			Return False
		Case $ButtonCancel
			GUIDelete($Form_AddModel)
			Return False
		Case $BtnBrowse
			$flag = 1
			if IsWinPE() Then $flag = 0
			$old = $SourceFolder + "\" + GUICtrlRead($InputFolder)
			$new = FileSelectFolder("Select Folder", $SourceFolder, $flag, $ModelFolder)	; $flag = 1 : Show Create Folder Button (does not work in WinPE)
			if $new <> "" Then
				$new = StringMid($new, StringLen($SourceFolder) + 2)
				GUICtrlSetData($InputFolder, $new)
			EndIf
			$ModelFolder = $SourceFolder & "\" & $new
			if $SourceFolder = "" or $new = "" Then $ModelFolder = "---dummy---"
			if IsFolder($ModelFolder) Then
				; User selected a new model specific folder - and the folder exists. Read the cmdlines.txt and GuiRunOnce.txt files from it and display their contents in the
				; $cmdlines and $RunOnce edit boxes.
				GUICtrlSetState($CmdLines, $GUI_ENABLE)
				GUICtrlSetState($RunOnce,  $GUI_ENABLE)
				$CmdLinesText = ReadCmdLines($ModelFolder)
				$RunOnceText = ReadRunOnce($ModelFolder)
			Else
				; User selected a new model specific folder - and the folder does not exist. Disable the $cmdlines and $RunOnce edit boxes.
				GUICtrlSetState($CmdLines, $GUI_DISABLE)
				GUICtrlSetState($RunOnce,  $GUI_DISABLE)
				$CmdLinesText = ""
				$RunOnceText = ""
			EndIf
			GUICtrlSetData($CmdLines, $CmdLinesText)
			GUICtrlSetData($RunOnce, $RunOnceText)
		Case $Btn_WMI
			ReadWmi($Manufacturer, $Model, $Version)
			GUICtrlSetData($InputModel, $Model)
		Case $ButtonOK
			$model = StringStripWS(GUICtrlRead($InputModel),3)
			$folder = StringStripWS(GUICtrlRead($InputFolder),3)
			If $model = "" Then
				MsgBox(0, "CopyDrivers", "A model is required")
			ElseIf $folder = "" Then
				MsgBox(0, "CopyDrivers", "A folder is required")
			Else
				$newCmdLinesText = GUICtrlRead($CmdLines)
				$newRunOnceText = GUICtrlRead($RunOnce)
				GUIDelete($Form_AddModel)
				if IsFolder($ModelFolder) Then
					if $newCmdLinesText <> $CmdLinesText Then SaveCmdLines($ModelFolder, $newCmdLinesText)
					if $newRunOnceText  <> $RunOnceText  Then SaveRunOnce ($ModelFolder, $newRunOnceText)
				EndIf
				return True
			EndIf
	EndSwitch
WEnd
	
EndFunc

; ===========================================================================================
; GUI function to edit the SOurce Folder and target folder settings
Func EditConfig(ByRef $source, ByRef $target)
; ===========================================================================================

#Region ### START Koda GUI section ### Form=Z:\install\AutoIt\koda_1.7.0.1\Forms\Form_Config.kxf
$Form_Config = GUICreate("Edit Config", 316, 197)
; GUISetIcon("D:\003.ico")
GUICtrlCreateGroup("", 8, 1, 297, 153)
$EditSource = GUICtrlCreateInput("", 16, 38, 217, 21)
$EditTarget = GUICtrlCreateInput("", 16, 110, 217, 21)
GUICtrlCreateLabel("Drivers Source Folder (Specify UNC path)", 16, 16, 200, 17)
GUICtrlCreateLabel("DriversTarget Folder", 16, 87, 100, 17)
$BtnBrowse = GUICtrlCreateButton("..", 244, 38, 57, 21, 0)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$BtnOK = GUICtrlCreateButton("&OK", 65, 163, 75, 25, 0)
$BtnCancel = GUICtrlCreateButton("&Cancel", 162, 163, 75, 25, 0)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

GUICtrlSetData($EditSource, $source)
GUICtrlSetData($EditTarget, $target)

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Return False
		Case $BtnCancel
			GUIDelete($Form_Config)
			Return False
		Case $BtnOK
			$source = StringStripWS(GUICtrlRead($EditSource),3)
			$target = StringStripWS(GUICtrlRead($EditTarget),3)
			if $source = "" Then
				MsgBox(0, "CopyDrivers", "A source folder is required")
			Else
				GUIDelete($Form_Config)
				Return True
			EndIf
		Case $BtnBrowse
			$new = FileSelectFolder("Select Source Folder", "", 0, $source)
			$new = StringStripWS($new,3)
			GUICtrlSetData($EditSource, $new)
			if $new <> "" Then $source = $new
	EndSwitch
WEnd
	
EndFunc

; ===========================================================================================
; Used by GUI to read cmdlines.txt from specified folder. The data is returned in a format ready to be fed into a GUI edit box
; (lines separated by CR-LF). The header line ([Commands]) is not included in the data.
Func ReadCmdLines($folder)
; ===========================================================================================
	$retstring = ""
	$filename = $folder & "\cmdlines.txt"
	$lineno = 0
	$file = FileOpen($filename, 0)	; 0 = read
	if $file = -1 Then return ""

	While 1
		$line = FileReadLine($file)
		If @error Then ExitLoop
		If StringStripWS($line,8) = "[commands]" Then ContinueLoop		; StringStripWS($line,8) strips all white space
		$line = StringStripWS($line, 3)	; 3 = strip leading & trailing while space
		if $line = "" Then ContinueLoop
		if StringLeft($line, 1) = '"' And StringRight($line, 1) = '"' Then
			$line = StringTrimLeft($line, 1)
			$line = StringTrimRight($line, 1)
		EndIf
		$line = StringStripWS($line, 3)	; 3 = strip leading & trailing while space
		if $line = "" Then ContinueLoop
		if $lineno > 0 Then $retstring = $retstring & @CRLF
		$lineno = $lineno + 1
		$retstring = $retstring & $line		
	Wend

	FileClose($file)
	return $retstring

EndFunc

; ===========================================================================================
; Used by GUI to read GuiRunOnce.ini from specified folder. The data is returned in a format ready to be fed into a GUI edit box
; (lines separated by CR-LF). The header line ([GuiRunOnce]) is not included in the data, nor are the CommandN= prefixes.
Func ReadRunOnce($folder)
; ===========================================================================================
	$retstring = ""
	$filename = $folder & "\GuiRunOnce.ini"
	$lineno = 0
	$lines = IniReadSection($filename, "GuiRunOnce")
	if @error Then return ""

	for $i = 1 to $lines[0][0]
		$line = $lines[$i][1]
		if $line = "" Then ContinueLoop
		if StringLeft($line, 1) = '"' And StringRight($line, 1) = '"' Then
			$line = StringTrimLeft($line, 1)
			$line = StringTrimRight($line, 1)
		EndIf
		$line = StringStripWS($line, 3)	; 3 = strip leading & trailing while space
		if $line = "" Then ContinueLoop
		if $lineno > 0 Then $retstring = $retstring & @CRLF
		$lineno = $lineno + 1
		$retstring = $retstring & $line		
	Next
	
	return $retstring

EndFunc

; ===========================================================================================
; Used by GUI to save cmdlines.txt in specified folder. The input data ($text) is the raw data as read from the GUI edit control. The header line ([Commands]) is not expected to
; be included in the input data.
Func SaveCmdLines($folder, $text)
; ===========================================================================================
	$filename = $folder & "\cmdlines.txt"
	if not IsFolder($folder) Then DirCReate($folder)
	$file = FileOpen($filename, 2)	; 2 = create
	$text = StringReplace($text, @LF, "")
	$lineno = 0
	$lines = StringSplit($text, @CR)
	for $i = 1 to $lines[0]
		$line = StringReplace($lines[$i], @LF, "")
		$line = StringStripWS($line, 3)	; 3 = strip leading & trailing while space
		if $line = "" Then ContinueLoop
		if StringLeft($line, 1) = '"' And StringRight($line, 1) = '"' Then
			$line = StringTrimLeft($line, 1)
			$line = StringTrimRight($line, 1)
		EndIf
		$line = '"' & $line & '"'
		if $lineno = 0 Then	FileWriteLine($file, "[Commands]")
		$lineno = $lineno + 1		
		FileWriteLine($file, $line)
	Next
	FileClose($file)
	if $lineno = 0 Then FileDelete($filename)		
	
EndFunc

; ===========================================================================================
; Used by GUI to save GuiRunOnce.ini in specified folder. The input data ($text) is the raw data as read from the GUI edit control. The header line ([GuiRunOnce]) is not expected to
; be included in the input data, nor are the "CommandN=" prefixes.
Func SaveRunOnce($folder, $text)
; ===========================================================================================
	$filename = $folder & "\GuiRunOnce.ini"
	if not IsFolder($folder) Then DirCReate($folder)
	$file = FileOpen($filename, 2)	; 2 = create
	$text = StringReplace($text, @LF, "")
	$lineno = 0
	$lines = StringSplit($text, @CR)
	for $i = 1 to $lines[0]
		$line = StringReplace($lines[$i], @LF, "")
		$line = StringStripWS($line, 3)	; 3 = strip leading & trailing while space
		if $line = "" Then ContinueLoop
		if StringLeft($line, 1) = '"' And StringRight($line, 1) = '"' Then
			$line = StringTrimLeft($line, 1)
			$line = StringTrimRight($line, 1)
		EndIf
		$line = 'Command' & $lineno & '="' & $line & '"'
		if $lineno = 0 Then	FileWriteLine($file, "[GuiRunOnce]")
		$lineno = $lineno + 1		
		FileWriteLine($file, $line)
	Next
	FileClose($file)
	if $lineno = 0 Then FileDelete($filename)		
	
EndFunc


; ===========================================================================================
; Return true if $s is a folder
Func IsFolder($s)
; ===========================================================================================
	If Not FileExists($s) Or Not StringInStr(FileGetAttrib($s), "D") Then Return False
	Return True
EndFunc

; ===========================================================================================
; Return true uf running under WinPE
Func IsWinPE()
; ===========================================================================================
	If EnvGet("SystemDrive") = "X:" Then Return True
	Return False
EndFunc


; ===========================================================================================
Func ErrorExit($msg, $exitcode)
; ===========================================================================================

	MsgBox(0x40010, "CopyDrivers", $msg, 10)	; 10 is timeout, i.e. the msgbox closes after 10 seconds
	Exit $exitcode

EndFunc
