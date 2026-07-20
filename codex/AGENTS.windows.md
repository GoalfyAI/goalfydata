# GoalfyData Install & Update Guide — Codex on Windows (Agent Edition)

While executing this guide, you must follow these rules:

1. Only run the commands listed here; only write to `%USERPROFILE%\.codex\.env` (line-level update) and the Codex plugin directory
2. Run every command in PowerShell
3. For first-time setup, send the user to https://goalfydata.ai/connect/skill; https://goalfydata.ai/settings is only the manual alternative for creating or managing a Key
4. The API Key must be the exact `gfk_` value sent by the user or returned in the setup message — never fabricate, rewrite, or substitute a placeholder
5. If the copied instructions or setup message contain an install code matching `^(inst|ref)_[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8,12}$`, preserve it exactly: append it as `gf_ref` to every `goalfydata.ai` page URL while keeping existing query parameters, and pass it to `uds-cli login` with `--install-code`. Do not append it to GitHub, CDN, or `api.goalfydata.ai` URLs. If no code was supplied, omit it. Never use an install code as a credential. This rule overrides static page URLs in the templates below
6. Whenever the user must act or provide something, output the corresponding ACTION REQUIRED template: as normal body text, never inside a code block or blockquote; the level-1 heading and bold must be preserved and never rewritten as plain sentences. The templates are written in English — when the user converses in another language, translate the content and keep the structure and emphasis intact
7. Do not declare success until the plugin is enabled, Codex has been restarted, the GoalfyData MCP tools (20, such as `uds_query` and `uds_dataset_manage`) are loaded, and a read-only MCP request succeeds

Every step starts with a check command: skip steps that are already done; re-running any step is safe.

---

## Installation

### Step 0: Resolve Codex CLI and detect the current state

Codex Desktop on Windows may expose a WindowsApps `codex.exe` that can be discovered but returns `Access is denied` when the agent starts it. Resolve a working CLI before running any plugin command.

```powershell
Get-Command codex -All -ErrorAction SilentlyContinue | Select-Object CommandType, Source, Path
$codexCli = 'codex'
& $codexCli plugin list
```

If the command succeeds, keep `$codexCli = 'codex'`. If it returns `Program 'codex.exe' failed to run: Access is denied`, use the user-directory app-server copy:

```powershell
$appServerCli = "$env:USERPROFILE\.codex\plugins\.plugin-appserver\codex.exe"
Test-Path $appServerCli
& $appServerCli plugin list
$codexCli = $appServerCli
```

Only set `$codexCli = $appServerCli` when that check succeeds. Use `& $codexCli` for every plugin command below. Do not request administrator access merely because the WindowsApps copy is blocked.

If neither candidate runs, output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Repair Codex Desktop

**Neither the WindowsApps Codex CLI nor the user-directory Codex CLI can run. Repair or reinstall Codex Desktop, then reopen this task and continue.**
```

After resolving `$codexCli`, run all state checks:

```powershell
Test-Path "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"                                              # CLI installed?
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" whoami                                               # logged in? (exit code 0 = yes)
Select-String '^GOALFY_UDS_API_KEY=' "$env:USERPROFILE\.codex\.env" -ErrorAction SilentlyContinue # MCP-side key configured?
& $codexCli plugin list | Select-String '^goalfydata@goalfydata\s+installed, enabled'             # plugin installed?
```

- All four pass → the user has a complete installation: **continue with Update**, asking the user for nothing
- Some pass → run only the steps for failing items; when `whoami` passes, skip Steps 1 and 3 (the key is already saved locally — do not ask for it again)
- None pass → perform the full installation from Step 1

Use the anchored plugin expression exactly. A broad search for `goalfydata` can falsely match the Windows username `goalfydata_test` in unrelated plugin paths.

### Step 1: Confirm the API Key

Output the template below to the user word for word (rendering any available `gf_ref` with the exact install code), and continue only after receiving the complete setup message or an exact API Key:

```markdown
# ACTION REQUIRED: Connect GoalfyData

**Open https://goalfydata.ai/connect/skill and verify your email address.**

**When verification is complete, copy the full setup message shown on the page and send it back to me. I will use its exact values to continue.**

**Alternatively, you can create or manage an API Key manually at https://goalfydata.ai/settings and send me the exact key.**
```

### Step 2: Install uds-cli

Check:

```powershell
Test-Path "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"
```

When already installed, **do not skip directly** — update to the latest version first, then proceed to Step 3:

```powershell
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" self-update --api-url https://api.goalfydata.ai
```

Both `already on the latest version` and `update succeeded: <old> → <new>` are normal.

If not installed:

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://cdn.goalfydata.ai/dataset-uds/install.ps1 | iex"
```

Success: output `uds-cli <version> installed to <path>\.goalfy\bin\uds-cli.exe`.

The install script writes `.goalfy\bin` into the user-level PATH (registry). Verify the persistence took effect:

```powershell
[Environment]::GetEnvironmentVariable("Path", "User") -like "*\.goalfy\bin*"
```

True means persisted. If False, you **must** write it — otherwise the user's future sessions cannot find `uds-cli`:

```powershell
[Environment]::SetEnvironmentVariable("Path", "$env:USERPROFILE\.goalfy\bin;" + [Environment]::GetEnvironmentVariable("Path", "User"), "User")
```

Re-run the check above after writing; this step is complete only when it returns True. If it is still False, report it honestly — do not skip.

If the `uds-cli` command is not visible in the current session, call it by absolute path `& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"` from then on — do not reinstall (the current session may not pick up a freshly written user-level PATH; command not visible does not mean not installed).

### Step 3: Log in

Check:

```powershell
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" whoami
```

Exit code 0 means already logged in; skip to Step 4 unless rotating the key.

Only after receiving the exact key, replace the token locally and run:

```powershell
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" login --api-key <user-provided-key> --api-url https://api.goalfydata.ai
```

Replace `<user-provided-key>` with the exact API Key received from the user — never execute the command with an example value or placeholder. If an exact install code was supplied, also pass it with `--install-code <code>`; otherwise omit that argument.

Success: report the real `Login succeeded` output and the masked API Key printed by `uds-cli`.

On failure:

- `unknown flag: --api-key` → run self-update and retry
- `API Key validation failed` → return to Step 1
- `WARNING: environment variable ...` → a stale key remains in the current environment; Step 5 and a full restart are mandatory

### Step 4: Install the plugin

Check:

```powershell
& $codexCli plugin list | Select-String '^goalfydata@goalfydata\s+installed, enabled'
```

If it produces output, skip to Step 5.

Normal installation:

```powershell
& $codexCli plugin marketplace add GoalfyAI/goalfydata
& $codexCli plugin add goalfydata@goalfydata
```

On a normal marketplace failure, refresh once and retry:

```powershell
& $codexCli plugin marketplace upgrade
& $codexCli plugin marketplace add GoalfyAI/goalfydata
& $codexCli plugin add goalfydata@goalfydata
```

If Git reports exit code 128 with `Failed to connect to github.com:443`, this is a network failure, not a plugin or API Key failure — report it plainly and retry after the network recovers; do not troubleshoot the plugin or the API Key.

Verify again with the anchored check. This step is complete only when the plugin shows `installed, enabled`.

### Step 5: Configure the API Key

Check whether the exact stored value matches the exact supplied key — if it does, skip to Step 6:

```powershell
Select-String '^GOALFY_UDS_API_KEY=' "$env:USERPROFILE\.codex\.env" -ErrorAction SilentlyContinue
```

Codex Desktop is an Electron app and does not read ordinary terminal environment variables. The key must be written to `%USERPROFILE%\.codex\.env`. Update by line and preserve unrelated content:

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.codex" | Out-Null
$envFile = "$env:USERPROFILE\.codex\.env"
$lines = @()
if (Test-Path $envFile) { $lines = @(Get-Content $envFile | Where-Object { $_ -notmatch '^GOALFY_UDS_API_KEY=' }) }
[System.IO.File]::WriteAllLines($envFile, ([string[]]($lines + 'GOALFY_UDS_API_KEY=<user-provided-key>')))
```

Write the file exactly as above — `[System.IO.File]::WriteAllLines` produces UTF-8 without BOM. Never use `Set-Content -Encoding utf8` here: Windows PowerShell 5.1 writes a UTF-8 BOM, the BOM prefixes the first line, and Codex then fails to recognize `GOALFY_UDS_API_KEY`.

Replace `<user-provided-key>` with the exact API Key received from the user — never write an example value or placeholder. Preserve every unrelated line, and re-run the check after writing to verify the stored value.

### Step 6: Restart and verify

The MCP connection only takes effect after restarting Codex; you cannot verify it until the user has restarted. Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart Codex

1. **Quit Codex completely and reopen it**
2. **Then come back to this conversation and tell me you have restarted (any message works) — I will verify the connection myself**
```

After the user confirms the restart, verify the connection yourself — do not ask the user to check anything: confirm the 20 GoalfyData MCP tools (`uds_query`, `uds_dataset_manage`, etc.) are available, and run one dataset list (for example the `uds_dataset_get` MCP tool) as the read-only self-check; its result also decides the closing message in the Report below. Do not create, modify, or delete data merely to test connectivity.

If the self-check fails: confirm `GOALFY_UDS_API_KEY` exists in `%USERPROFILE%\.codex\.env` and the key shows as valid at https://goalfydata.ai/settings , then ask the user to fully restart again.

### Report

After all steps, report with this template:

```
GoalfyData installation result:

[Done]
- uds-cli installed and logged in (version = the actual `uds-cli version` output, e.g. abc1234-yyyymmdd; account = the login email)
- Plugin goalfydata installed and enabled
- API Key written to %USERPROFILE%\.codex\.env
- 20 MCP tools loaded and a read-only request succeeded

[Action required from you]
- (none / fully restart Codex and tell me when it is done — I will verify the connection)

[Not completed]
- (none / list reasons)
```

Then, only if every step is done and [Not completed] is empty, use the dataset list from the verification self-check to choose the closing message:

- If the list contains datasets shared to the user that are still waiting to be accepted, output the template below instead of the onboarding message (fill in the real sharer and dataset names from the list; when there are several, list them all):

```markdown
# You have shared datasets waiting for you

**<sharer> shared the dataset "<dataset-name>" with you, and it is waiting for you to accept.**

**Would you like to accept it and start analyzing it right away? Just tell me and I will take it from there.**
```

- Otherwise, append the onboarding message below to the report:

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

### Step 1: Resolve the working Codex CLI

Repeat Installation Step 0. Never assume the PATH copy works.

### Step 2: Update the plugin

For a Git marketplace:

```powershell
& $codexCli plugin marketplace upgrade goalfydata
& $codexCli plugin remove goalfydata@goalfydata
& $codexCli plugin add goalfydata@goalfydata
```

### Step 3: Update uds-cli

```powershell
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" self-update
```

Success is `already on the latest version` or `update succeeded: <old> → <new>`.

### Step 4: Restart to take effect

Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart to take effect

**Quit Codex completely and reopen it — the update only takes effect afterwards.**
```

---

## Rotating the API Key

Run this section when the user wants to rotate the API Key (or the old key has been deleted/invalidated). Understand the key's activation model first — otherwise the rotation silently fails:

- The key lives in two places: `%USERPROFILE%\.goalfy\config.json` (written by login, read by uds-cli) and `%USERPROFILE%\.codex\.env` (used for the MCP request header, and also injected into the agent's session environment)
- Precedence: environment variables override the config — if `%USERPROFILE%\.codex\.env` is not updated, the stale environment value overrides the newly saved key
- Activation timing: the config takes effect immediately; `%USERPROFILE%\.codex\.env` and the session environment only take effect **after a full restart**

Execute in order (skip the Step 0 routing in the rotation case):

1. Direct the user to get a new key: run Installation Step 1 (output the Connect GoalfyData template)
2. Log in again with the new key: run Installation Step 3, **never skipped just because whoami passes** (the old key may not be deleted yet)
3. Update the MCP-side storage: run Installation Step 5, **unconditionally — never skipped because its check passes**. `%USERPROFILE%\.codex\.env` still holds the old key; without this update, MCP and new sessions keep using the old key after restart (whether login printed `WARNING: environment variable ...` only reflects the current session environment and must not be used as a reason to skip)
4. Consistency check: confirm both `%USERPROFILE%\.goalfy\config.json` and `%USERPROFILE%\.codex\.env` now hold the new key (compare the first characters after gfk_)
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
| `uds-cli` is not recognized | Use `%USERPROFILE%\.goalfy\bin\uds-cli.exe`; reinstall only if the file is absent |
| `codex.exe` returns `Access is denied` | Use `%USERPROFILE%\.codex\plugins\.plugin-appserver\codex.exe`; this is not an API Key failure |
| Both Codex CLI candidates fail | Repair or reinstall Codex Desktop, then restart |
| Git clone exits 128 / `github.com:443` fails | Network failure, not a plugin or API Key problem; report it and retry after the network recovers |
| Plugin check matches unrelated entries | Use `^goalfydata@goalfydata\s+installed, enabled`; do not search broadly for the username substring |
| `unknown flag: --api-key` | Outdated CLI; run `self-update` first, then retry |
| `irm` download fails | Check the network; the install script already enforces TLS 1.2 — if it still fails, report the exact error to the user |
| login reports validation failed | Direct the user to https://goalfydata.ai/settings to verify the key, recreating it if necessary |
| MCP not connected | Check `GOALFY_UDS_API_KEY` in `%USERPROFILE%\.codex\.env`, then ask the user to fully restart Codex (you cannot restart on the user's behalf) |
| Tools return unauthenticated | Key missing or invalid; return to Installation Step 1 |
| login succeeds but subsequent commands return 401/unauthenticated | A stale key remains in the environment (which takes precedence over the saved login config). Follow "Rotating the API Key" and have the user restart |
| The `.env` key line exists but Codex reports `GOALFY_UDS_API_KEY` missing | The file starts with a UTF-8 BOM (typically written by `Set-Content -Encoding utf8`); rewrite it with the Installation Step 5 block (BOM-less UTF-8), then fully restart |
| Exported in terminal but Desktop cannot connect | The Desktop app does not read terminal environment variables; the key must be in `%USERPROFILE%\.codex\.env` (Installation Step 5) |
| New terminals still cannot find uds-cli | User-level PATH not applied; redo the persistence check and write in Installation Step 2 |
