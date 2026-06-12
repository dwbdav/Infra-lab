# Add UltraVNC to MDT WinPE

Source article: https://blog.wuibaille.fr/2024/05/adding-tools-to-winpe/

## Purpose

Inject UltraVNC into an MDT WinPE boot image and start it before the Lite Touch wizard for remote support.

## Files

- `extra.cmd` : disables the WinPE firewall and starts `winvnc.exe`.
- `Unattend.xml` : optional WinPE unattend example that runs `X:\extra.cmd` before `LiteTouch.wsf`.
- `UltraVnc/` : UltraVNC binaries and configuration files used by the WinPE extra directory.

## MDT setup

In Deployment Workbench:

1. Open the deployment share properties.
2. Go to **Windows PE**.
3. Set the x64 **Extra directory to add** to this folder.
4. Set the prestart command to `X:\extra.cmd` if `extra.cmd` is copied at the root of the extra directory.
5. Completely regenerate the boot image.

## Values to adapt

- `UltraVnc/ultravnc.ini` contains placeholder password hash values:
  - `REPLACE_WITH_GENERATED_ULTRAVNC_HASH`
  - `REPLACE_WITH_GENERATED_ULTRAVNC_VIEWONLY_HASH`
- Generate your own UltraVNC password hashes before using this in a real boot image.
- `UltraVnc/options.vnc` uses `192.168.0.x` as a local lab placeholder. Replace it with the target address for your viewer/server workflow.

## Publication check

- No GitHub token detected.
- No API key or bearer token pattern detected.
- No email or public credential detected.
- Original UltraVNC password hashes were replaced with placeholders.
- The original non-allowed sample IP was replaced with `192.168.0.x`.
