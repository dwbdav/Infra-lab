Set cmddism=dism
Set cmdwusa=wusa
Set cmdpowershell=powershell
Set cmdreg=reg
Set cmdpowercfg=powercfg
Set cmdcscript=cscript
if defined PROCESSOR_ARCHITEW6432 Set cmddism=%SystemRoot%\Sysnative\cmd.exe /c Dism
if defined PROCESSOR_ARCHITEW6432 Set cmdpowershell=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdwusa=%SystemRoot%\sysnative\wusa.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe
if defined PROCESSOR_ARCHITEW6432 Set cmdpowercfg=%SystemRoot%\Sysnative\cmd.exe /c powercfg
if defined PROCESSOR_ARCHITEW6432 Set cmdcscript=%SystemRoot%\Sysnative\cscript.exe
 
::You can use the variables (Use sysnative for 32-bit processes.)
%cmdreg% add HKLM\Software\leblogosd ...
%cmdpowershell% -command ...
%cmddism% /add-driver ...
 
%cmdpowershell% -noprofile -command "Set-ExecutionPolicy bypass LocalMachine"
%cmdpowershell% -file "%~dp0script.ps1"