# Synology Wake-on-LAN

Simple Wake-on-LAN web interface for Synology Web Station.

Source article: [WOL with synology with Windows Administration Tools](https://blog.infra-lab.fr/2024/08/wol-with-synology/)

## Files

| File | Purpose |
| --- | --- |
| `index.html` | HTML page with buttons that call `wol.php`. |
| `wol.php` | Sends the Wake-on-LAN magic packet to the configured broadcast address. |

## Notes

- Example MAC addresses are placeholders and must be replaced before use.
- The broadcast address in `wol.php` is `192.168.0.255`.
- Requires PHP sockets support on Synology Web Station.

