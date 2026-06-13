# IIS Web.config for Ivanti EPM Shares

IIS `web.config` template for Ivanti EPM web shares and file repositories.

## Files

| File | Description |
| --- | --- |
| `web.config` | Enables directory browsing and adjusts IIS request filtering for repository files. |

## Behavior

The configuration:

- Enables directory browsing.
- Allows files without extensions.
- Adds a default MIME type for extensionless files.
- Removes several IIS request filtering blocks for file extensions often present in repositories.
- Removes the `bin` hidden segment restriction.

## Usage

Copy `web.config` to the root of the IIS virtual directory or web share used by Ivanti EPM.

## Notes

- Review IIS security requirements before using this on a public-facing server.
- This template is intended for controlled internal Ivanti EPM distribution shares.
