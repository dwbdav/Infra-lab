# WSUS Auto Approval

Source article: https://blog.wuibaille.fr/2024/10/automate-assign-patch-to-group/

## Purpose

Automatically promote WSUS update approvals from one computer group to another after a defined delay, accept EULAs when required, and decline superseded updates when a newer update is approved.

## Files

- `Wsus-ManageApprovals.ps1` : PowerShell script for approval promotion and superseded update cleanup.

## Default workflow

- `Pilot` -> `Global1` after 5 days.
- `Global1` -> `Global2` after 5 days.
- Superseded updates are declined when their replacement is approved for `Global2`.
- Logs are written to `C:\logs`, keeping the latest 60 log files.

## Values to adapt

Edit the top of `Wsus-ManageApprovals.ps1`:

- `$SyncApprovals`
- `$logFolder`
- `$maxLogs`
- group names such as `Pilot`, `Global1`, and `Global2`

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or UNC path detected.
