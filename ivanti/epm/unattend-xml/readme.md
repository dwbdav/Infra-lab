# Unattend XML for Ivanti EPM Provisioning

Windows `unattend.xml` template used with Ivanti EPM OS provisioning for Windows 10 or Windows 11 deployments.

Source article: [Provisionning - Deployment of Windows 10 with Ivanti EPM](https://blog.infra-lab.fr/2023/04/epm-deploiement-de-windows-10/)

## Files

| File | Description |
| --- | --- |
| `unattend.xml` | Windows answer file template for EPM provisioning. |

## Variables

The file uses Ivanti provisioning variables. Declare them in EPM before importing the answer file:

| Variable | Description |
| --- | --- |
| `%ldHostname%` | Computer name provided by Ivanti EPM. |
| `%administratorpassword%` | Local Administrator password injected at deployment time. |
| `%AutoLogon%` | Number of automatic logons after deployment. |

## Important Security Note

`unattend.xml` contains password fields with:

```xml
<PlainText>true</PlainText>
```

The committed file only contains the placeholder `%administratorpassword%`, not a real password. Do not replace this value with a real password before committing or publishing.

## Included Settings

- Sets computer name from `%ldHostname%`.
- Enables the local Administrator account.
- Configures AutoLogon using `%administratorpassword%`.
- Skips OOBE screens.
- Sets French locale and `Romance Standard Time`.
- Disables first logon animation.
- Sets Internet Explorer home page to `https://wiki.wuibaille.fr`.

## Usage

Import `unattend.xml` in the Ivanti EPM OS provisioning template and enable variable insertion during import.

## Notes

- Review locale, timezone, owner, organization, and home page values before production use.
- Keep passwords as Ivanti variables rather than hardcoded values.
