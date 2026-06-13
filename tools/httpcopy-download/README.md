# HTTP Copy Download

Small `wget.exe` based helper for mirroring a public HTTP directory locally.

Blog category: [Windows Administration Tools](https://blog.wuibaille.fr/category/administration/tools/)

## Files

| File | Purpose |
| --- | --- |
| `Download.cmd` | Runs `wget.exe --mirror --no-parent` against the configured HTTP folder. |
| `wget.exe` | Windows `wget` executable used by the command file. |

## Notes

- The included command mirrors the public `nas.wuibaille.fr` download folder.
- Adjust the URL in `Download.cmd` before using it for another source.

