# GoalfyData Install & Update Guide — Codex on Windows (Agent Edition)

While executing this guide, you must follow these rules:

1. Only run the commands listed here; only write to `%USERPROFILE%\.codex\.env` (line-level update) and the Codex plugin directory
2. When mentioning obtaining or verifying the API Key to the user, include the settings link https://goalfydata.ai/settings
3. The API Key must come from the user — never fabricate one or proceed with a placeholder
4. Run all commands in PowerShell
5. Whenever the user must act or provide something, output the corresponding ACTION REQUIRED template: as normal body text, never inside a code block or blockquote; the level-1 heading and bold must be preserved and never rewritten as plain sentences. The templates are written in English — when the user converses in another language, translate the content and keep the structure and emphasis intact

Every step starts with a check command: skip steps that are already done; re-running any step is safe.

---

## Installation

### Step 0: Detect the current state (install vs update)

The following are all check commands — no user interaction. Route by the result:

```powershell
Test-Path "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"          # CLI installed?
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" whoami           # logged in? ($LASTEXITCODE 0 = yes)
Select-String GOALFY_UDS_API_KEY "$env:USERPROFILE\.codex\.env" # MCP-side key configured?
codex plugin list | Select-String goalfydata                     # plugin installed?
```

- All four pass → the user has a complete installation: **switch to the Update flow directly**, asking the user for nothing
- Some pass → run only the steps for the failing items; when whoami passes, skip Steps 1 and 3 (the key is already saved locally — do not ask for it again)
- None pass → full installation from Step 1

### Step 1: Confirm the API Key

Output the template below to the user word for word, and continue only after receiving the key:

```markdown
# ACTION REQUIRED: Provide your GoalfyData API Key

**Do you already have a GoalfyData API Key (shaped like `gfk_xxx`)? If so, send it to me directly.**

**If not, create one in GoalfyData: https://goalfydata.ai/settings ("Settings → API Key"; the plaintext is shown only once at creation — store it safely). No account yet? Open https://goalfydata.ai to sign up.**

Send me the API Key once created, and I will finish the remaining steps.
```

### Step 2: Install uds-cli

Check: `Test-Path "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"` — True means installed. When already installed, **do not skip directly** — update to the latest version first, then proceed to Step 3:

```powershell
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" self-update --api-url https://api.goalfydata.ai
```

Both `already on the latest version` and `update succeeded: <old> → <new>` are normal.

If not installed, install it:

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://cdn.goalfydata.ai/dataset-uds/install.ps1 | iex"
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

On failure: `unknown flag: --api-key` means an outdated CLI — run `& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" self-update` and retry; `API Key validation failed` means an invalid key — return to Step 1. If login prints `WARNING: environment variable ...`, a stale key remains in the environment — Step 5 is mandatory and the user must restart afterwards.

### Step 4: Install the plugin

Check: `codex plugin list | Select-String goalfydata` — if it produces output, skip to Step 5.

```powershell
codex plugin marketplace add GoalfyAI/goalfydata
codex plugin add goalfydata@goalfydata
```

On failure: run `codex plugin marketplace upgrade` to refresh the cache, then retry.

### Step 5: Configure the API Key

Check: `Select-String GOALFY_UDS_API_KEY "$env:USERPROFILE\.codex\.env"` — if present with the correct value, skip to Step 6.

Codex Desktop is an Electron app and does not read terminal environment variables; the key must be written to `%USERPROFILE%\.codex\.env`. Update by line; do not touch other content in the file:

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.codex" | Out-Null
$envFile = "$env:USERPROFILE\.codex\.env"
$lines = @()
if (Test-Path $envFile) { $lines = @(Get-Content $envFile | Where-Object { $_ -notmatch '^GOALFY_UDS_API_KEY=' }) }
$lines + 'GOALFY_UDS_API_KEY=<user-provided-key>' | Set-Content $envFile
```

Re-run the check command after writing to confirm the line is present.

### Step 6: Restart and verify

The MCP connection only takes effect after restarting Codex; you cannot verify it in the current session — the user must do this. Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart Codex and verify MCP

1. **Quit Codex completely and reopen it**
2. **After restarting, confirm `goalfydata-mcp` is connected with 20 tools listed** (`uds_query`, `uds_dataset_manage`, etc.)

If it fails: confirm `GOALFY_UDS_API_KEY` exists in `%USERPROFILE%\.codex\.env` and the key shows as valid at https://goalfydata.ai/settings , then fully restart again.
```

### Report

After all steps, report with this template:

```
GoalfyData installation result:

[Done]
- uds-cli installed and logged in (version = the actual `uds-cli version` output, e.g. abc1234-yyyymmdd; account = the login email)
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

Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart to take effect

**Quit Codex completely and reopen it — the update only takes effect afterwards.**
```

---

## Rotating the API Key

Run this section when the user wants to rotate the API Key (or the old key has been deleted/invalidated). Understand the key's activation model first — otherwise the rotation silently fails:

- The key lives in two places: `~/.goalfy/config.json` (written by login, read by uds-cli) and `%USERPROFILE%\.codex\.env` (used for the MCP request header, and also injected into the agent's session environment)
- Precedence: environment variables override the config — if `%USERPROFILE%\.codex\.env` is not updated, the stale environment value overrides the newly saved key
- Activation timing: the config takes effect immediately; `%USERPROFILE%\.codex\.env` and the session environment only take effect **after a full restart**

Execute in order (skip the Step 0 routing in the rotation case):

1. Direct the user to create a new key: run Installation Step 1 (output the key-request template)
2. Log in again with the new key: run Installation Step 3, **never skipped just because whoami passes** (the old key may not be deleted yet)
3. Update the MCP-side storage: run Installation Step 5, **unconditionally — never skipped because its check passes**. `%USERPROFILE%\.codex\.env` still holds the old key; without this update, MCP and new sessions keep using the old key after restart (whether login printed `WARNING: environment variable ...` only reflects the current session environment and must not be used as a reason to skip)
4. Consistency check: confirm both `~/.goalfy/config.json` and `%USERPROFILE%\.codex\.env` now hold the new key (compare the first characters after gfk_)
5. Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart to activate the new API Key

**Quit Codex completely and reopen it.** The current session environment and the MCP connection are still using the old key; they only switch to the new key after a full restart.

**After restarting, if the old key has not been deleted yet, consider removing it at https://goalfydata.ai/settings to avoid mixing keys.**
```

Acceptance (in the user's new session after restart): `uds-cli whoami` shows the new key prefix, and MCP tools no longer return unauthenticated.

If the user no longer has this guide, output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Get the setup text again

**Open the GoalfyData integration page: https://goalfydata.ai/integrations/codex**

**Copy the setup text on the page and send it to me again — I will complete every step automatically, including rotating the API Key.**
```

---

## Troubleshooting

| Symptom | Handling |
|---|---|
| `uds-cli` is not recognized as a command | Use the absolute path `& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"`; only reinstall if the file does not exist (Installation Step 2) |
| `unknown flag: --api-key` | Outdated CLI; run `self-update` first, then retry |
| `irm` download fails | Check the network; the install script already enforces TLS 1.2 — if it still fails, report the exact error to the user |
| login reports validation failed | Direct the user to https://goalfydata.ai/settings to verify the key, recreating it if necessary |
| login succeeds but subsequent commands return 401/unauthenticated | A stale key remains in the environment (which takes precedence over the saved login config). Re-run the Installation flow per "Rotating the API Key" and have the user restart |
| MCP not connected | Check `GOALFY_UDS_API_KEY` in `%USERPROFILE%\.codex\.env`, then ask the user to fully restart Codex (you cannot restart on the user's behalf) |
| Tools return unauthenticated | Key missing or invalid; return to Installation Step 1 |
| Exported in terminal but Desktop cannot connect | The Desktop app does not read terminal environment variables; the key must be in `%USERPROFILE%\.codex\.env` (Installation Step 5) |
| New terminals still cannot find uds-cli | User-level PATH not applied; redo the persistence check and write in Installation Step 2 |
