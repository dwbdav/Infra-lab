#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Comment=This program connects a drive letter to the preferred server for Windows or WinPE.
#AutoIt3Wrapper_Res_Fileversion=3.0.0.1
#AutoIt3Wrapper_Res_LegalCopyright=LANdesk Software
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.0.0
 Author:         Jan Buelens, LANDesk Software

 Script Function:
	Map a drive to the preferred server.

Change History:
    V1.0 01 July 2009. Original version. Based on earlier C++ program.
    V2.0 020 Jan 2010. Chnaged for LDMS 9.0. PreferredServer.dat file lives in different place and has different format.
	V3.0 06 June 2011. Made work in Windows XP (32-bit) and Windows 7 (32 and 64-bit).

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here

Const $progname = "prefmap V3.0"
Dim $share = ""
Dim $drvletter = ""
Dim $user = ""
Dim $pwd = ""
Dim $varname = ""
Dim $bVerbose = False
Dim $bSilent = False
$logfilename = ""			; log file (from /log command line parameter)
$log = -1
Dim $PrefServerFile8 = ""
Dim $PrefServerFile9 = ""
Dim $CoreServer = ""
Dim $LDMSPath = ""

If IsWinPE() Then
	$PrefServerFile8 = "x:\LANDesk\ManagementSuite\sdmcache\preferredserver.dat"	; LDMS WinPE 8.x
	$PrefServerFile9 = "x:\ldclient\preferredservers.dat"							; LDMS WinPE 9.0
	$CoreServer	= RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Intel\LANDesk\EventLog", "CoreServer")
Else
	If StringInStr(@OSArch, "86") Then
	$CoreServer = RegRead("HKEY_LOCAL_MACHINE\Software\Intel\LANDesk\EventLog", "CoreServer")
	$PrefServerFile9 = "c:\program files\landesk\ldclient\sdmcache\preferredservers." & $CoreServer & ".dat"
	$LDMSPath = "c:\program files\landesk\ldclient\"
	ElseIf StringInStr(@OSArch, "64") Then
	$CoreServer = RegRead("HKEY_LOCAL_MACHINE\Software\Wow6432Node\Intel\LANDesk\EventLog", "CoreServer")
	$PrefServerFile9 = "c:\program files (x86)\landesk\ldclient\sdmcache\preferredservers." & $CoreServer & ".dat"
	$LDMSPath = "c:\program files (x86)\landesk\ldclient\"
	EndIf
EndIf

Dim $PrefServerFile = ""



; ===========================================================================================
; Validate command line parameters
; ===========================================================================================

For $n = 1 to $CmdLine[0]
	$s = ""
	If ValParam($CmdLine[$n], "shr", $s) Then
		$share = $s
	ElseIf ValParam($CmdLine[$n], "drv", $s) Then
		$drvletter = $s
	ElseIf ValParam($CmdLine[$n], "usr", $s) Then
		$user = $s
	ElseIf ValParam($CmdLine[$n], "pwd", $s) Then
		$pwd = $s
	ElseIf ValParam($CmdLine[$n], "var", $s) Then
		$varname = $s
	ElseIf ValParam($CmdLine[$n], "log", $s) Then
		$logfilename = $s
	ElseIf $CmdLine[$n] = "/v" Or $CmdLine[$n] = "-v"  Then
		$bVerbose = True;
	Else
		Usage()
	EndIf
Next

if $logfilename = "" Then $logfilename = StringTrimRight(@ScriptFullPath, 3) & "log"
$log = FileOpen($logfilename, 2)

if $varname = "" Then
	; No variable name (/var) is specified. The other 3 parameters (/drv, /shr, /usr) must be present
	if $share = "" then Usage()
	if $user = "" then Usage()
	if $drvletter = "" then Usage()
EndIf
If $share <> "" Or $user <> "" Or $drvletter <> "" Then
	; if one of (/drv, /shr, /usr) is present, all 3 must be present
	if $share = "" then Usage()
	if $user = "" then Usage()
	if $drvletter = "" then Usage()
	; validate format of /drv
	if StringLen($drvletter) > 2 Then Usage()
	if StringLen($drvletter) = 1 Then $drvletter &= ":"
	if StringRight($drvletter, 1) <> ":" Then Usage()
	$drvletter = StringUpper($drvletter)
	if $drvletter < "A:" Or $drvletter > "Z:" Then Usage()
EndIf

;If Not IsWinPE() Then ErrorExit("This program must be run under WinPE", 2)

If not GetPrefServerFile() Then
	; ===================================================================================
	; Use sdclient to download a small dummy file from the core server. As a side effect,
	; a preferredserver.dat file is left in x:\LANDesk\ManagementSuite\sdmcache.
	; Whether the download is successful does not matter
	; ===================================================================================

	;$CoreServer	= RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Intel\LANDesk\LDWM", "CoreServer")
	if $bVerbose Then MsgBox(0, $progname, "core server: " & $CoreServer, 5)
	If IsWinPE() Then
		$SdclientCommandLine = "X:\ldclient\sdclient.exe /f /o /dest=x:\ldclient\win_prov_files.xml /p=http://" & $CoreServer & "/ldlogon/provisioning/win_prov_files.xml"
		if $bVerbose Then MsgBox(0, $progname, "command line: " & $SdclientCommandLine, 10)
		LogMessage("Dummy download from core server so sdclient/lddwnld.dll gets hold of preferredserver(s).dat")
		LogMessage("command line: " & $SdclientCommandLine)
		RunWait($SdclientCommandLine, "x:\ldclient")
	Else
		$SdclientCommandLine = $LDMSPath & "sdclient.exe /f /o /p=http://" & $CoreServer & "/ldlogon/provisioning/win_prov_files.xml /requirepref"
		if $bVerbose Then MsgBox(0, $progname, "command line: " & $SdclientCommandLine, 10)
		LogMessage("Dummy download from core server so sdclient/lddwnld.dll gets hold of preferredserver(s).dat")
		LogMessage("command line: " & $SdclientCommandLine)
		RunWait($SdclientCommandLine, $LDMSPath)
	EndIf
EndIf

If not GetPrefServerFile() Then ErrorExit("preferredserver(s).dat not found", 3)
LogMessage("preferredserver.dat found at " & $PrefServerFile)
$line = FileReadLine($PrefServerFile)
if $line = "" Then ErrorExit("PreferredServer(s).dat file is empty", 4)
LogMessage("preferredserver(s).dat file contents: " & $line)

; ===================================================================================
; Found preferredserver.dat. It is a text file with no CR-LF. If there are multiple preferred servers,
; they are separated by a semicolon. The preferred server list may or may not be prefixed with a time stamp
; and a question mark.
; Expected formats for LDMS 8.8:
;    SERVER1
;    SERVER1;SERVER2
; Expected formats for LDMS 8.8:
;    12349439485?SERVER1
;    12349439485?SERVER1;SERVER2
; ===================================================================================

$serverlist = ""
$array = StringSplit($line,"?")
If $array[0] = 1 Then
	; there was no question mark
	$serverlist = $line
ElseIf $array[0] = 2 Then
	; there was 1 question mark - take the substring after the question mark
	$serverlist = $array[2]
Else
	ErrorExit("preferredserver.dat, invalid format", 41)
EndIf

$array = StringSplit($serverlist,";")
$servername = $array[1]

; ===================================================================================
; When using local user names, we may need something like <machinename>\<username>.
; If the username we got from the command line includes a substring "$server$", replace
; with server name from preferredserver.dat
; ===================================================================================

$user = StringReplace($user, "$server$", $servername)

if $bVerbose Then MsgBox(0, $progname, "preferred server: " & $servername, 5)
LogMessage("preferred server: " & $servername)

if $share <> "" Then
	$unc = "\\" & $servername & "\" & $share

	if $bVerbose Then MsgBox(0, $progname, "connecting " & $drvletter & " to " & $unc & " as " & $user, 5)
	LogMessage("connecting " & $drvletter & " to " & $unc & " as " & $user)

	$ret = DriveMapAdd($drvletter, $unc, 0, $user, $pwd)
	if $ret = 0 Then
		$errmsg = "DriveMapAdd(" & $drvletter & ", " & $unc & ", " & $user & ", <pwd>) failed. "
		if @error = 1 Then $errmsg &= "Win32 error code " & @extended
		if @error = 2 Then $errmsg &= "Access Denied"
		if @error = 3 Then $errmsg &= "Drive letter already assigned"
		if @error = 4 Then $errmsg &= "Invalid drive letter"
		if @error = 5 Then $errmsg &= "UNC path not found"
		if @error = 6 Then $errmsg &= "Invalid password"
		ErrorExit($errmsg, 5)
	EndIf

	if $bVerbose Then MsgBox(0, $progname, "connection successful", 5)
	LogMessage("connection successful")
EndIf

if $varname <> "" Then
	$base = "HKLM\System\CurrentControlSet\Control\Session Manager\Environment"
	RegWrite($base, $varname, "REG_SZ", $servername)
	if @error Then ErrorExit("RegWrite, error " & @error, 6)
	LogMessage("Environment variable set")
EndIf

FileClose($log)


; ===========================================================================================
; The location of the preferredserver.dat file is different between LDMS 8.8 and 9.0. This function looks in the
; two possible places and sets a global variable ($PrefServerFile) to the correct path. If the file is found in
; neither place, the return value is false.
Func GetPrefServerFile()
; ===========================================================================================
	$PrefServerFile = ""
	If FileExists($PrefServerFile8) Then
		$PrefServerFile = $PrefServerFile8
		Return True
	EndIf
	If FileExists($PrefServerFile9) Then
		$PrefServerFile = $PrefServerFile9
		Return True
	EndIf
	Return False
EndFunc

; ===========================================================================================
; Return true if running under WinPE
Func IsWinPE()
; ===========================================================================================
	If EnvGet("SystemDrive") = "X:" Then Return True
	Return False
EndFunc

; ===========================================================================================
Func ErrorExit($msg, $exitcode)
; ===========================================================================================

	LogMessage($msg)
	FileClose($log)
	if not $bSilent Then MsgBox(0x40010, $progname, $msg, 10)	; 10 is timeout, i.e. the msgbox closes after 10 seconds
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

; ===========================================================================================
Func LogMessage($msg)
; ===========================================================================================
	FileWriteLine($log, $msg)
EndFunc

; ===========================================================================================
Func Usage()
; ===========================================================================================
	Msgbox (0, $progname & " by Jan Buelens", _
	                            "This program maps a drive to the preferred server." & @CRLF _
	                  & @CRLF & "Usage:" _
	                  & @CRLF & "   /shr=	share" _
	                  & @CRLF & "   /drv=	drive letter" _
	                  & @CRLF & "   /usr=	user name" _
	                  & @CRLF & "   /pwd=	password" _
	                  & @CRLF & "   /var=	environment variable" _
	                  & @CRLF & "   /v	 verbose" & @CRLF _
	                  & @CRLF & "Use this program only under WinPE." _
	                  & @CRLF & "If there are multiple preferred servers, the first one will be used." _
	                  & @CRLF & "If you are using a local machine account to connect, you may want to" _
	                  & @CRLF & "include a $server$ substring in the user name. The program will replace" _
	                  & @CRLF & "it with the preferred server name." _
	                  & @CRLF & "" _
	                  & @CRLF & "If a /var parameter is specified, a system environment variable will" _
	                  & @CRLF & "set to the preferred server name. You probably need the RunEnv tool to" _
	                  & @CRLF & "use the environment variable. If you only want prefmap to set an" _
	                  & @CRLF & "environment variable, without mapping a drive, use the /var parameter" _
	                  & @CRLF & "only." _
	                  & @CRLF & "" _
					  )

	Exit 1

EndFunc

