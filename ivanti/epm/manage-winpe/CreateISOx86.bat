@echo off
setlocal

if "%~1"=="" (
  echo Usage: %~nx0 EPM_CORE_FQDN
  exit /b 1
)

set servlandesk=%~1

if exist C:\winpe_x86 rd C:\winpe_x86 /S /Q
call copype x86 C:\winpe_x86

copy "\\%servlandesk%\ldmain\landesk\vboot\boot.wim" C:\winpe_x86\media\sources\boot.wim
if exist "%~dp0winpe_x86.iso" del "%~dp0winpe_x86.iso"

call Makewinpemedia /iso C:\winpe_x86 "%~dp0winpe_x86.iso"
rd C:\winpe_x86 /S /Q
