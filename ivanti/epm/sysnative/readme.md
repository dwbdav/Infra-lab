# Sysnative Command Template

Batch template for running 64-bit Windows tools from a 32-bit process on 64-bit Windows.

## Files

| File | Description |
| --- | --- |
| `template.cmd` | Defines command variables that automatically switch to `Sysnative` when needed. |

## Why Sysnative

When a 32-bit process runs on 64-bit Windows, calls to `System32` are redirected to `SysWOW64`. This can be a problem during provisioning or software deployment when the script must run the 64-bit version of tools such as:

- `reg.exe`
- `powershell.exe`
- `dism.exe`
- `wusa.exe`
- `powercfg.exe`
- `cscript.exe`

`Sysnative` is a Windows alias that lets a 32-bit process access the real 64-bit `System32` folder.

## Usage

Use the variables from `template.cmd` instead of calling tools directly:

```cmd
%cmdreg% add HKLM\Software\leblogosd ...
%cmdpowershell% -file "%~dp0script.ps1"
%cmddism% /add-driver ...
```

The template switches automatically when `PROCESSOR_ARCHITEW6432` is defined:

```cmd
if defined PROCESSOR_ARCHITEW6432 Set cmdreg=%SystemRoot%\sysnative\reg.exe
```

## Notes

- Use this pattern when an Ivanti EPM task, installer, or script runs in a 32-bit context.
- If the process is already 64-bit, the default command names are used.
