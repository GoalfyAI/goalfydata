# GoalfyData Install & Update Guide — Codex on Windows (Agent Edition)

While executing this guide, you must follow these rules:

1. Only run the commands listed here; only write to `%USERPROFILE%\.codex\.env` (line-level update) and the Codex plugin directory
2. When mentioning obtaining or verifying the API Key to the user, include the console link https://goalfydata.ai/settings
3. The API Key must come from the user — never fabricate one or proceed with a placeholder
4. Run all commands in PowerShell

Every step starts with a check command: skip steps that are already done; re-running any step is safe.

---

## Installation

### Step 1: Confirm the API Key

First ask the user whether they already have a GoalfyData API Key (shaped like `gfk_xxx`):

- Yes → ask the user to send it to you and proceed to Step 2
- No → output the following to the user verbatim, and continue only after receiving the key:

> ## ACTION REQUIRED: Create your GoalfyData API Key
>
> **Create an API Key in the GoalfyData console: https://goalfydata.ai/settings ("Settings → API Key", shaped like `gfk_xxx`; the plaintext is shown only once at creation — store it safely.)**
>
> **If you do not have a GoalfyData account yet, open https://goalfydata.ai to sign up.**
>
> Send me the API Key once created, and I will finish the remaining steps.

### Step 2: Install uds-cli

Check: `Test-Path "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"` — True means installed; skip to Step 3.

```powershell
irm https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.ps1 | iex
```

Success: output `uds-cli <version> installed to <path>\.goalfy\bin\uds-cli.exe`.

The install script writes `.goalfy\bin` into the user-level PATH (registry) and injects it into the current session. Verify the persistence took effect:

```powershell
[Environment]::GetEnvironmentVariable("Path", "User") -like "*\.goalfy\bin*"
```

True means persisted. If False, you **must** write it — otherwise the user's future sessions cannot find `uds-cli`:

```powershell
[Environment]::SetEnvironmentVariable("Path", "$env:USERPROFILE\.goalfy\bin;" + [Environment]::GetEnvironmentVariable("Path", "User"), "User")
```

Re-run the check above after writing; this step is complete only when it returns True. If it is still False, report it honestly — do not skip.

If the `uds-cli` command is not visible in the current session, call it by absolute path `& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"` from then on — do not reinstall.

### Step 3: Log in

Check: run `& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" whoami` — `$LASTEXITCODE` 0 means already logged in; skip to Step 4.

```powershell
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" login --api-key <user-provided-key> --api-url https://api.goalfydata.ai
```

Success: output `Login succeeded` and `API Key: gfk_xxx...`.

On failure: `unknown flag: --api-key` means an outdated CLI — run `& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" self-update` and retry; `API Key validation failed` means an invalid key — return to Step 1.

### Step 4: Install the plugin

Check: `codex plugin list | Select-String goalfydata` — if it produces output, skip to Step 5.

```powershell
codex plugin marketplace add GoalfyAI/goalfydata
codex plugin add goalfydata@goalfydata
```

On failure: run `codex plugin marketplace upgrade` to refresh the cache, then retry.

### Step 5: Configure the API Key

Check: `Select-String GOALFY_UDS_API_KEY "$env:USERPROFILE\.codex\.env"` — if present with the correct value, skip to Step 6.

Codex Desktop does not inherit terminal environment variables; the key must be written to `%USERPROFILE%\.codex\.env`. Update by line; do not touch other content in the file:

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.codex" | Out-Null
$envFile = "$env:USERPROFILE\.codex\.env"
$lines = @()
if (Test-Path $envFile) { $lines = @(Get-Content $envFile | Where-Object { $_ -notmatch '^GOALFY_UDS_API_KEY=' }) }
$lines + 'GOALFY_UDS_API_KEY=<user-provided-key>' | Set-Content $envFile
```

Re-run the check command after writing to confirm the line is present.

### Step 6: Restart and verify

The MCP connection only takes effect after restarting Codex; you cannot verify it in the current session — the user must do this. Output to the user verbatim:

> ## ACTION REQUIRED: Restart Codex and verify MCP
>
> 1. **Quit Codex completely and reopen it**
> 2. **After restarting, confirm `goalfydata-mcp` is connected with 20 tools listed** (`uds_query`, `uds_dataset_manage`, etc.)
>
> If it fails: confirm `GOALFY_UDS_API_KEY` exists in `%USERPROFILE%\.codex\.env` and the key shows as valid in the console at https://goalfydata.ai/settings , then fully restart again.

### Report

After all steps, report with this template:

```
GoalfyData installation result:

[Done]
- uds-cli installed and logged in (version x.y.z, account xxx@example.com)
- Plugin goalfydata installed
- API Key written to %USERPROFILE%\.codex\.env

[Action required from you]
- Fully restart Codex and confirm goalfydata-mcp is connected (see above)

[Not completed]
- (none / list reasons)

From here, just describe what you want, e.g. "Build a dataset from this Excel file."
More usage at https://goalfydata.ai .
```

---

## Update

### Step 1: Update the plugin

```powershell
codex plugin marketplace upgrade goalfydata
codex plugin remove goalfydata@goalfydata
codex plugin add goalfydata@goalfydata
```

### Step 2: Update uds-cli

```powershell
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" self-update
```

Success: output `already on the latest version` or `update succeeded: <old> → <new>`.

### Step 3: Restart to take effect

Output to the user verbatim:

> ## ACTION REQUIRED: Restart to take effect
>
> **Quit Codex completely and reopen it — the update only takes effect afterwards.**

---

## Troubleshooting

| Symptom | Handling |
|---|---|
| `uds-cli` is not recognized as a command | Use the absolute path `& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"`; only reinstall if the file does not exist (Installation Step 2) |
| `unknown flag: --api-key` | Outdated CLI; run `self-update` first, then retry |
| `irm` download fails | Check the network; the install script already enforces TLS 1.2 — if it still fails, report the exact error to the user |
| login reports validation failed | Direct the user to https://goalfydata.ai/settings to verify the key, recreating it if necessary |
| MCP not connected | Check `GOALFY_UDS_API_KEY` in `%USERPROFILE%\.codex\.env`, then ask the user to fully restart Codex (you cannot restart on the user's behalf) |
| Tools return unauthenticated | Key missing or invalid; return to Installation Step 1 |
| New terminals still cannot find uds-cli | User-level PATH not applied; redo the persistence check and write in Installation Step 2 |
