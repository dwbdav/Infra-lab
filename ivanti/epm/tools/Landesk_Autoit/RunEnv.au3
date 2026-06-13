#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.2.10.0
 Author:         Jan Buelens, LANDesk Software

 Script Function:
	This script may help in an OSD or Provisioning context to make environment variables useful. The author knows of no other way
	whereby one provisioning action can use an environment variable set by another provisioning action. Even using setx to set a system
	environment variable doesn't do the trick.
	This script gets around the issue by reading the system environment variables from the registry before launching the specified
	command line. The child process will see all the system environment variables.

#ce ----------------------------------------------------------------------------

$progname = "RunEnv V1.0"

If $CmdLine[0] = 0 Then Usage()
If $CmdLine[0] > 0 And ($CmdLine[1] = "/?" Or $CmdLine[1] = "-?" Or $CmdLine[1] = "help") Then
	Usage()
EndIf

$CommandLine = ""

For $n = 1 to $CmdLine[0]
	$str = $CmdLine[$n]
	; $str = StringReplace($str, '"', '""')
	if StringInStr($str, " ") > 0 And StringLeft($str,1) <> '"' Then
		$str = '"' & $str & '"'
	EndIf
	if $CommandLine <> "" Then
		$CommandLine = $CommandLine & " "
	EndIf
	$CommandLine = $CommandLine & $str
Next


$base = "HKLM\System\CurrentControlSet\Control\Session Manager\Environment"
   for $n = 1 to 9999
   	$valname = RegEnumVal($base, $n)
   	if @error Then ExitLoop
   	$val = RegRead($base, $valname)
	$env = EnvGet($valname)
	if $env = "" Then
		; This environment variable doesn't exist - set it. We only set variables that do not exist in the currrent environment. We don't override
		; variables that exist. This would violate the rule whereby user environmrent variables take priority over system environment variables.
		EnvSet($valname, $val)
	EndIf
	
Next

; Msgbox ("0", "RunEnv V1.0", "Command Line: ==" & $CommandLine & "==")

AutoItSetOption ( "ExpandEnvStrings", 1)	; This tells AutoIt to expand Env Vars
$ExitCode = RunWait($CommandLine)
if @error Then ErrorExit("Failed to run command: " & $CommandLine, 2)
	
; ErrorExit("Exit Code: " & $ExitCode, $ExitCode)

Exit $ExitCode

; ===========================================================================================
Func Usage()
; ===========================================================================================

	Msgbox ("0", $progname, _
	                            "This program runs the specified command line, after refreshing the system" _
	                  & @CRLF & "environment variables." & @CRLF _
	                  & @CRLF & "In a normal windows environment, when a new system environment variable is" _
	                  & @CRLF & "created (e.g. with setx), running processes will not see the new environment" _
	                  & @CRLF & "variable, but future processes launched by the windows shell will." & @CRLF _
					  & @CRLF & "Under WinPE, the new environment variable seems to remain invisible even to" _
					  & @CRLF & "future processes. If this is a problem, use RunEnv. A process launched by" _
					  & @CRLF & "RunEnv will see all environment variables. To use RunEnv, just prefix the" _
					  & @CRLF & "normal command line with RunEnv." _
					  )

	Exit 1

EndFunc

; ===========================================================================================
Func ErrorExit($msg, $exitcode)
; ===========================================================================================

	MsgBox(0x40010, $progname, $msg, 10)	; 10 is timeout, i.e. the msgbox closes after 10 seconds
	Exit $exitcode

EndFunc
