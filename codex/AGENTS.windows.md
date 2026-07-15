# GoalfyData Install & Update Guide — Codex on Windows (Agent Edition)

While executing this guide, you must follow these rules:

1. Only run the commands listed here; only write to `%USERPROFILE%\.codex\.env` (line-level update) and the Codex plugin directory
2. For first-time setup, send the user to https://goalfydata.ai/connect/skill; https://goalfydata.ai/settings is only the manual alternative for creating or managing a Key
3. The API Key must be the exact `gfk_` value sent by the user or returned in the setup message — never fabricate, rewrite, or substitute a placeholder
4. If the copied instructions or setup message contain an install code matching `^(inst|ref)_[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8,12}$`, preserve it exactly: append it as `gf_ref` to every `goalfydata.ai` page URL while keeping existing query parameters, and pass it to `uds-cli login` with `--install-code`. Do not append it to GitHub, CDN, or `api.goalfydata.ai` URLs. If no code was supplied, omit it. Never use an install code as a credential. This rule overrides static page URLs in the templates below
5. Run all commands in PowerShell
6. Whenever the user must act or provide something, output the corresponding ACTION REQUIRED template: as normal body text, never inside a code block or blockquote; the level-1 heading and bold must be preserved and never rewritten as plain sentences. The templates are written in English — when the user converses in another language, translate the content and keep the structure and emphasis intact

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

- All four pass → the user has a complete installation: **continue with Update**, asking the user for nothing
- Some pass → run only the steps for the failing items; when whoami passes, skip Steps 1 and 3 (the key is already saved locally — do not ask for it again)
- None pass → full installation from Step 1

### Step 1: Confirm the API Key

Output the template below to the user word for word (rendering any available `gf_ref` with the exact install code), and continue only after receiving the complete setup message or an exact API Key:

```markdown
# ACTION REQUIRED: Connect GoalfyData

**Open https://goalfydata.ai/connect/skill and verify your email address.**

**When verification is complete, copy the full setup message shown on the page and send it back to me. I will use its exact values to continue.**

**Alternatively, you can create or manage an API Key manually at https://goalfydata.ai/settings and send me the exact key.**
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

Replace `<user-provided-key>` with the exact API Key received from the user — never execute the command with an example value or placeholder. If an exact install code was supplied, also pass it with `--install-code <code>`; otherwise omit that argument.

Success: report the real `Login succeeded` output and the masked API Key value printed by uds-cli.

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

Replace `<user-provided-key>` with the exact API Key received from the user — never write an example value or placeholder. Preserve every unrelated line.

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
```

Then, only if every step is done and [Not completed] is empty, append the onboarding message below to the report:

```
GoalfyData has been installed successfully.

You can now ask your Agent to turn data scattered across files, business systems, or webpages into reusable business datasets that stay up to date over time. Your data won't disappear when a conversation ends, and the business definitions and update rules you confirm will be saved with it.

Simply tell me about a data task you need to organize or analyze repeatedly.

For example:

"Every day, I need to combine Shopify order and advertising reports to analyze GMV, refund rate, and return on ad spend. Rebuilding everything from scratch takes time, so I want to turn this into a repeatable analysis that I can update whenever new data arrives."

I'll first confirm your data sources, metric definitions, and update method, then help you turn them into a dataset you can continue using.

Once created, you can keep using the same data and business definitions across conversations, Agents, and devices. You can also automate updates, share data with permission controls, or publish it as a data dashboard.

To learn more about GoalfyData, visit https://goalfydata.ai.
```

If anything is under [Not completed], do NOT output the onboarding message. Instead, state plainly what failed and why, give the fix or the exact step to re-run, and continue helping the user until the installation succeeds.

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

1. Direct the user to get a new key: run Installation Step 1 (output the Connect GoalfyData template)
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
| login succeeds but subsequent commands return 401/unauthenticated | A stale key remains in the environment (which takes precedence over the saved login config). Follow "Rotating the API Key" and have the user restart |
| MCP not connected | Check `GOALFY_UDS_API_KEY` in `%USERPROFILE%\.codex\.env`, then ask the user to fully restart Codex (you cannot restart on the user's behalf) |
| Tools return unauthenticated | Key missing or invalid; return to Installation Step 1 |
| Exported in terminal but Desktop cannot connect | The Desktop app does not read terminal environment variables; the key must be in `%USERPROFILE%\.codex\.env` (Installation Step 5) |
| New terminals still cannot find uds-cli | User-level PATH not applied; redo the persistence check and write in Installation Step 2 |
