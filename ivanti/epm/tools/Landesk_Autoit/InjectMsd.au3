#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Comment=This program injects a mass storage driver previously captured by CaptureMsd
#AutoIt3Wrapper_Res_Description=InjectMsd
#AutoIt3Wrapper_Res_Fileversion=1.1
#AutoIt3Wrapper_Res_LegalCopyright=Copyright LANDesk Software
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 InjectMsd Version 1.0.1  08 Dec 2008
 AutoIt Version: 3.2.12.1
 Author:         Jan Buelens, Landesk Software

 Script Function:
	Inject a mass storage driver into a freshly restored image. Context: we are still running under WinPE. The target machine has just been restored
	from an image. We are about to reboot the target into mini-setup. But before the target reboots, we need to inject the correct mass storage sriver into
	it.
	
	This script expects a path as a command line parameter. Within that path, there should be following:
	-1- A .inf and a .sys file, to be copied to c:\Windows\inf and c:\Windows\System32\drivers respectively
	-2- A subfolder called "windows", to be copied recursively to c:\windows. This subfolder contains any additional files to be injected, e.g. DLLs.
	    There is a redundancy here (the .sys and .inf could just as well be in this subfolder), but item -1- above is still believed to be convenient. 
	-3- One or more .reg files. These were probably exported from a working machine using the same mass storage driver. Typically, two .reg files
	    will be needed. One to describe the "service" under HKLM\CurrentControlSet\Services. A second one to describe the driver's subkey under 
		HKLM\CurrentControlSet\Control\CriticalDeviceDatabase.
		The script imports these .reg files into the target system's registry. 
		
	The path passed as a command line parameter must have write access because -1- the program will make a temp copy of the .reg files it finds, -2- the
	program will create a log file called injectmsd.log.
	
		
	If something goes wrong, the script returns a non-zero exit code. There will also be a message box that goes away after 10 seconds.
	
	Change history:
	V1.0.1 (08 Dec 08). In addition to HKLM\Software and HKLM\System, a .reg file can now also write to the target's HKEY_USERS\.Default. 
	v1.1   (07 July 09). The msd folder is no longer required as a command line parameter if a copydrivers.ini file (with a DriversTarget parameter in it)
			is present in the folder from which this program is running. If copydrivers.ini has the "typical" DriversTarget path of c:\drivers, InjectMsd will
			default to c:\drivers\msd. Non-existence of this folder will not be considered an error (exit code 0). If an msdfolder is specified on the command
			line, however, it is required to exist.
			The log file is in a different place than before (c:\drivers if that's what's in copydrivers.ini/DriversTarget).
			
		
#ce ----------------------------------------------------------------------------


#Include <File.au3>

$progname = "InjectMsd V1.1"
Dim $logfilename = ""			; log file (from /log command line parameter)
Dim $log = -1


Dim $MsdFolder = ""

; ===========================================================================================
; Validate command line parameters. There should be one command line parameter = base folder
; ===========================================================================================

For $n = 1 to $CmdLine[0]
	$s = ""
	$c = StringLeft($CmdLine[$n],1)
	if $n = 1 And $c <> "/" And $c <> "-" Then
		$MsdFolder = $CmdLine[1]
	ElseIf ValParam($CmdLine[$n], "log", $s) Then
		$logfilename = $s
	Else
		Usage()
	EndIf
Next

LogOpen($logfilename)

if $MsdFolder = "" Then
	; If no folder was specified on the command line, see if there is a copydrivers.ini with a DriversTarget parameter and default to msd subfolder off it.
	; Example: if DriversTarget has its typical value of c:\drivers, default to c:\drivers\msd. If that folder does not exist, don't complain - this may be
	; a normal case of a machine type that does not require an msd folder
	$iniFilename = PathConcat(@ScriptDir, "copydrivers.ini") ; @ScriptDir is folder in which this script (or compiled program) resides
	LogIniSection($iniFilename, "Config")
	if FileExists($iniFilename) Then
		$DriverPath = IniRead($iniFilename, "Config", "DriversTarget", "")	; normally c:\drivers
		if $DriverPath <> "" Then
			$MsdFolder = PathConcat($DriverPath, "msd")
			if not IsFolder($MsdFolder) Then
				LogMessage("Default msd folder (" & $MsdFolder & ") does not exist. No work to do - exiting")
				Exit 0
			EndIf
		EndIf
	EndIf
EndIf

if $MsdFolder = "" Then
	; No msd folder was specified on the command line and we couldn't take a default from copydrivers.ini. Complain.
	Usage()
EndIf

; If we defaulted the msdfolder based on DriversTarget in copydrivers.ini, we have already exited with a zero return code if the folder doesn't exist.
; But if an msdfolder was specified on the command line and it doesn't exist, we still complain.
if not IsFolder($MsdFolder) Then ErrorExit("Folder " & $MsdFolder & " does not exist.", 2)


; ===========================================================================================
; If there is a subfolder called windows, copy it to c:\Windows
; ===========================================================================================

CopyWindows()	; Copy Windows subfolder if any to C:\Windows

; ===========================================================================================
; Find .inf and .sys files and copy to C:\Windows\Inf and c:\windows\system32\drivers respectively. This
; is strictly speaking redundant since same can be achieved using CopyWindows. But is probably convenient.
; ===========================================================================================

$search = FileFindFirstFile(PathConcat($MsdFolder, "*.inf"))
While 1
    $file = FileFindNextFile($search) 
    If @error Then ExitLoop
	LogMessage("Copying " & $file & " to c:\windows\inf\")
    FileCopy(PathConcat($MsdFolder, $file), "c:\windows\inf\", 1)	; 1 = overwrite
	If @error Then LogMessage("Copy of " & $file & " failed")
WEnd
FileClose($search)	; Close the search handle

$search = FileFindFirstFile(PathConcat($MsdFolder, "*.sys"))
While 1
    $file = FileFindNextFile($search) 
    If @error Then ExitLoop
	LogMessage("Copying " & $file & " to c:\windows\system32\drivers\")
    FileCopy(PathConcat($MsdFolder, $file), "c:\windows\system32\drivers\", 1)	; 1 = overwrite
	If @error Then LogMessage("Copy of " & $file & " failed")
WEnd
FileClose($search)	; Close the search handle

; ===========================================================================================
; Find .reg files. For each .reg file, call ProcessReg.
; ===========================================================================================

$search = FileFindFirstFile(PathConcat($MsdFolder, "*.reg"))
While 1
    $file = FileFindNextFile($search) 
    If @error Then ExitLoop
	LogMessage("Processing " & $file)
    ProcessReg(PathConcat($MsdFolder, $file))
WEnd
FileClose($search)	; Close the search handle

; ===========================================================================================
; Done
; ===========================================================================================



; ===========================================================================================
; If the folder that we got as a command line parameter has a subfolder called "windows", then xcopy it to C:\Windows
Func CopyWindows()
; ===========================================================================================
	Local $SourceFolder = PathConcat($MsdFolder, "Windows")
	Local $TargetFolder = "C:\Windows"
	if Not IsFolder($SourceFolder) Then Return False
	LogMessage("Copying " & $MsdFolder & "\Windows to c:\windows")
	DirCreate($TargetFolder)
	If Not IsFolder($TargetFolder) Then ErrorExit("Unable to create target folder: " & $TargetFolder, 6)
	If Not DirCopy($SourceFolder, $TargetFolder, 1) Then ErrorExit("Unable to copy folder: " & $TargetFolder, 7)	; 1 means overwrite existing files
	Return True
EndFunc

; ===========================================================================================
; Import a .reg file into the target's registry. Make a temp copy of the .reg file (called .reg1), with modified registry key names. We need to modify
; the registry key names because e.g. HKLM\System refers to the WinPE registry. We change HKLM\System to HKLM\System1 and HKLM\Software to HKLM\Software1.
; We also need to change CurrentControlSet to ControlSet001 because CurrentControlSet is an alias that only exists in the running system, not in the target's
; System hive on disk.
; We then use the REG LOAD command to mount the target system's HKLM\System registry hive as HKLM\System1 and HKLM\Software as HKLM\Software1. After that,
; we can use the REG IMPORT command to import the modified .reg file into the target's registry.
Func ProcessReg($file)
; ===========================================================================================
	$tempfile = $file & "1"
	
	LogMessage("Making temp copy of " & $file & ", the copy is called " & $tempfile)
	FileCopy($file, $tempfile, 1)	; 1 = overwrite
	if @error then ErrorExit("Unable to create " & $tempfile, 8)
	if not FileExists($tempfile) then  ErrorExit("Unable to create " & $tempfile, 9)
	LogMessage("Editing " & $tempfile & ", replacing registry root key names")
	$count1 = _ReplaceStringInFile($tempfile, "HKEY_LOCAL_MACHINE\System",   "HKEY_LOCAL_MACHINE\System1")
	$count2 = _ReplaceStringInFile($tempfile, "System1\CurrentControlSet",   "System1\ControlSet001")
	$count3 = _ReplaceStringInFile($tempfile, "HKEY_LOCAL_MACHINE\Software", "HKEY_LOCAL_MACHINE\Software1")
	$count4 = _ReplaceStringInFile($tempfile, "HKEY_USERS\.DEFAULT", "HKEY_LOCAL_MACHINE\Default1")	
	
	if $count1 > 0 Then
		if not FileExists("c:\windows\system32\config\system") Then ErrorExit("File not found: c:\windows\system32\config\system", 10)
		RunCommand("reg load HKLM\System1 c:\windows\system32\config\system")
		if not HasSubKey("HKLM\System1") Then ErrorExit("Something went wrong loading target's HKLM\System", 11)
	EndIf
	if $count3 > 0 Then
		if not FileExists("c:\windows\system32\config\software") Then ErrorExit("File not found: c:\windows\system32\config\software", 12)
		RunCommand("reg load HKLM\Software1 c:\windows\system32\config\software")
		if not HasSubKey("HKLM\Software1") Then ErrorExit("Something went wrong loading target's HKLM\Software", 13)
	EndIf
	if $count4 > 0 Then
		if not FileExists("c:\windows\system32\config\default") Then ErrorExit("File not found: c:\windows\system32\config\default", 12)
		RunCommand("reg load HKLM\Default1 c:\windows\system32\config\default")
		if not HasSubKey("HKLM\Default1") Then ErrorExit("Something went wrong loading target's HKEY_USERS\.DEFAULT", 13)
	EndIf
		
	RunCommand("reg import " & $tempfile)
	
	if $count1 > 0 Then RunCommand("reg unload HKLM\System1")
	if $count3 > 0 Then RunCommand("reg unload HKLM\Software1")
	if $count4 > 0 Then RunCommand("reg unload HKLM\Default1")
	
EndFunc

; ===========================================================================================
; Return true if $s has a registry subkey
Func HasSubKey($s)
; ===========================================================================================
	SetError(0)
	Dim $subkey = ""
	$subkey = RegEnumKey($s, 1)
	if @error Then Return False
	If $subkey = "" Then Return False
	Return True
EndFunc

; ===========================================================================================
; Run specified command and include stdout and stderr output in our log file
Func RunCommand($cmd)
; ===========================================================================================
	LogMessage("Running this command line: " & $cmd)
	FileClose($log)
	$command = "cmd /c " & $cmd & " >>" & $logfilename & " 2>&1"
	RunWait($command)
	$log = FileOpen($logfilename, 1)	; 1 = write, append mode
EndFunc

; ===========================================================================================
Func Usage()
; ===========================================================================================

	Msgbox ("0", $progname, _
	                            "This program injects a Mass Storage Driver previously captured with the" _
	                  & @CRLF & "CaptureMsd program."  & @CRLF _
					  & @CRLF & "Usage:  InjectMsd [msdfolder] [parameters]" & @CRLF _ 
	                  & @CRLF & "Msdfolder is the path where the driver files captured by CaptureMsd" _
	                  & @CRLF & "are stored (typically a .sys, .inf and .reg). The msdfolder parameter" _
	                  & @CRLF & "is optional if a copydrivers.ini file with appropriate parameters is" _
	                  & @CRLF & "present in the folder from which InjectMsd is running."  & @CRLF _
	                  & @CRLF & "Parameters:" _
	                  & @CRLF & "/log=<logfile> : log file" _
					  )

	Exit 1

EndFunc

; ===========================================================================================
; Concatenate a filename ($s) with a base path
Func PathConcat($base, $s)
; ===========================================================================================
	$base = StringStripWS($base,3)
	$s = StringStripWS($s,3)
	if StringRight($base,1) <> "\" Then $base &= "\"
	if StringLeft($s,1) = "\" Then $s = StringTrimLeft($s,1)
	Return $base & $s
EndFunc

; ===========================================================================================
; Return true if $s is a folder
Func IsFolder($s)
; ===========================================================================================
	If Not FileExists($s) Or Not StringInStr(FileGetAttrib($s), "D") Then Return False
	Return True
EndFunc
	
; ===========================================================================================
; Return true if $s is a network path. Must be full path.
Func IsRemote($s)
; ===========================================================================================
	If StringLeft($s, 2) = "\\" Then Return True
	Local $drive = StringLeft($s, 3)
	if DriveGetType($drive) = "Network" Then Return True
	Return False
EndFunc

; ===========================================================================================
Func LogCmdLine()
; ===========================================================================================
	Local $n
	LogMessage($progname & ", command line parameter(s): " & $CmdLine[0])
	For $n = 1 to $CmdLine[0]
		LogMessage("   " & $CmdLine[$n])
	Next
EndFunc

; ===========================================================================================
Func LogMessage($msg)
; ===========================================================================================
	FileWriteLine($log, $msg)
EndFunc

; ===========================================================================================
Func LogIniSection($inifilename, $inisection, $msg = Default)
; ===========================================================================================
	Local $i
	if $msg = Default Then
		LogMessage($inifilename & ",section [" & $inisection & "]:")
	Else
		LogMessage($msg)
	EndIf
	Local $section = IniReadSection($inifilename, $inisection)
	if @error Then
		if not FileExists($inifilename) Then
			LogMessage("   File does not exist: " & $inifilename)
			Return
		EndIf
		LogMessage("   " & $inifilename & " includes no [" & $inisection & "] section")
		Return
	EndIf
	For $i = 1 to $section[0][0]
		LogMessage("   " & $section[$i][0] & " = " & $section[$i][1])
	Next
EndFunc

; ===========================================================================================
Func LogOpen(ByRef $logfilename)
; ===========================================================================================

	Local $scriptName = StringTrimRight(@ScriptName, 4)
	While 1
		If $logfilename <> "" Then
			; log filename specified on command line
			$log = FileOpen($logfilename, 10)	; 10 = 2 (write, create) + 8 (create path)
			ExitLoop
		EndIf			

		; No /log command line parameter. If there is a copydrivers.ini file with a DriversTarget parameter (typically c:\drivers), create the log in there
		Local $iniFilename = PathConcat(@ScriptDir, "copydrivers.ini")
		Local $DriverPath = IniRead($iniFilename, "Config", "DriversTarget", "")
		if $DriverPath <> "" Then
			$DriverPath = StringStripWS($DriverPath, 3)
			if StringRight($DriverPath, 1) <> "\" Then $DriverPath &= "\"
			$logfilename = $DriverPath & $scriptName & ".log"
			$log = FileOpen($logfilename, 10)	; 10 = 2 (write, create) + 8 (create path)
			if $log <> -1 Then ExitLoop
		EndIf
		
		; No /log command parameter and no copydrivers.ini. If running from a local path, create log in folder of running program		
		If Not IsRemote(@ScriptFullPath) Then
			$logfilename = StringTrimRight(@ScriptFullPath, 3) & "log"
			$log = FileOpen($logfilename, 2)
			if $log <> -1 Then ExitLoop
		EndIf
		
		; failed to create log
		$log = -1
		$logfilename = ""
		return
	Wend
	
	LogCmdLine()
EndFunc

; ===========================================================================================
Func ErrorExit($msg, $exitcode)
; ===========================================================================================
	LogMessage($msg)
	FileClose($log)
	MsgBox(0x40010, $progname, $msg, 10)	; 10 is timeout, i.e. the msgbox closes after 10 seconds
	Exit $exitcode
EndFunc

; ===========================================================================================
; parse command line parameter such as /keyw=something. Examples:
;    ValParam("/path=c:\temp", "path", $value) sets $value to "c:\temp" and returns True
;    ValParam("-path=c:\temp", "path", $value) sets $value to "c:\temp" and returns True
;    ValParam("/path=c:\temp", "dir", $value) sets $value to "" and returns False
Func ValParam($param, $keyword, ByRef $value)
; ===========================================================================================
	$value = ""
	Local $p1 = "/" & $keyword & "="
	Local $p2 = "-" & $keyword & "="
	Local $len = StringLen($p1)
	if StringLen($param) < ($len + 1) Then Return False
	Local $t = StringLeft($param, $len)
	if ($t <> $p1) And ($t <> $p2) Then Return False
	$value = StringMid($param, $len + 1)	; 1 based
	Return True

EndFunc
