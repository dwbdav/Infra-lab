# Export MDT Folders

Source article: to be linked when the matching blog post is published or identified.

## Purpose

Export MDT drivers, packages, operating systems and applications by reading the MDT `Control` XML files and copying source folders while preserving group structure.

## Files

- `ExportMDT.vbs` : VBScript export tool.
- `ExportMDT.ini` : configuration file for the MDT deployment share and export destination.

## Configuration

```ini
Text_NomDP=\\DISKSTATION\deploymentshare$
Text_NomRepExport=c:\temp
```

`\\DISKSTATION\deploymentshare$` is a local lab/example deployment share. Replace it with your MDT deployment share when reusing the script elsewhere.

## Run

```bat
cscript //nologo ExportMDT.vbs
```

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email or public credential detected.
- `\\DISKSTATION\deploymentshare$` is intentionally kept as an allowed lab/local example.
