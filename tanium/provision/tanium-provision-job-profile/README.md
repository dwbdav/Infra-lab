# Tanium Provision: Add a Choose Job Profile Prompt

Source article: https://blog.wuibaille.fr/2026/05/tanium-provision-job-profile/

## Purpose

Configure a Tanium Provision job profile prompt and reuse the selected value as a tag for software deployment targeting.

## Files

- `Customer-PE-Pre.ps1` : WinPE pre-script that displays the job profile selection prompt.
- `Customer.ps1` : script that imports the Tanium client module and applies the selected value.
- `CustomerDemolab.zip` : archive containing the same two scripts for Tanium package usage.

## Publication check

- No GitHub token detected.
- No password, API key or bearer token pattern detected.
- No email, internal URL, private IP or UNC path detected.
- `CustomerDemolab.zip` was inspected and contains only `Customer-PE-Pre.ps1` and `Customer.ps1`.
