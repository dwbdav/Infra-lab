@echo off
setlocal

if "%~1"=="" (
  echo Usage: %~nx0 EPM_CORE_FQDN
  exit /b 1
)

set servlandesk=%~1

if exist C:\winpe_amd64 rd C:\winpe_amd64 /S /Q
call copype amd64 C:\winpe_amd64

copy "\\%servlandesk%\ldmain\landesk\vboot\boot_x64.wim" C:\winpe_amd64\media\sources\boot.wim
if exist "%~dp0winpe_amd64.iso" del "%~dp0winpe_amd64.iso"

call Makewinpemedia /iso C:\winpe_amd64 "%~dp0winpe_amd64.iso"
rd C:\winpe_amd64 /S /Q
