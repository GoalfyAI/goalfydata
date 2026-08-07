# GoalfyData Install & Update Guide — Codex on Windows (Agent Edition)

While executing this guide, you must follow these rules:

1. Only run the commands listed here; only write to the installer-owned `%USERPROFILE%\.goalfy\` directory, the user-level PATH entry described in Step 2, `%USERPROFILE%\.codex\.env` (line-level update), and the Codex plugin directory
2. Run every command in PowerShell
3. Never ask the user to create, copy, paste, or send an API Key; `uds-cli login` opens the verified setup page and receives the credential locally
4. Never print or read the plaintext Key into the conversation. After browser login, use Codex's existing protected local file access to copy the saved `api_key` from `%USERPROFILE%\.goalfy\config.json` into the existing Codex environment setting; do not add a helper runtime or generated synchronization script
5. If the copied instructions or setup message contain an install code matching `^(inst|ref)_[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8,12}$`, preserve it exactly: append it as `gf_ref` to every `goalfydata.ai` page URL while keeping existing query parameters, and pass it to `uds-cli login` with `--install-code`. Do not append it to GitHub, CDN, or `api.goalfydata.ai` URLs. If no code was supplied, omit it. Never use an install code as a credential. This rule overrides static page URLs in the templates below
6. Whenever the user must act or provide something, output the corresponding ACTION REQUIRED template: as normal body text, never inside a code block or blockquote; the level-1 heading and bold must be preserved and never rewritten as plain sentences. The templates are written in English — when the user converses in another language, translate the content and keep the structure and emphasis intact
7. Do not declare success until the plugin is enabled, Codex has been restarted, the GoalfyData MCP tools (20, such as `uds_query` and `uds_dataset_manage`) are loaded, and a read-only MCP request succeeds
8. Run every installation, update, login, and configuration command yourself. Never send shell commands to the user or ask them to open PowerShell

Every step starts with a check command: skip steps that are already done; re-running any step is safe.

---

## Installation

### Mandatory sandbox and permission handling

This conversation is running inside Codex's sandbox and approval system, not inside the user's later Windows terminal. The current session has a built-in scoped escalation path for commands that need network access or writes outside the workspace.

1. Run every check and command in this guide yourself.
2. Treat a failing `irm https://cdn.goalfydata.ai/...` download (host cannot be resolved), other blocked network access, or a write denial under `%USERPROFILE%\.goalfy`, the user-level PATH registry entry, `%USERPROFILE%\.codex\.env`, or the plugin directory as a sandbox restriction first. It is not evidence that the website is down, the API Key is invalid, or the user's normal network is broken.
3. When a required command is blocked by the sandbox, request the narrowest available sandbox permission escalation for the required network destination and/or user-configuration path, then retry the command yourself. Issue at most one sandbox-elevation prompt for one installation attempt: request a reusable command prefix or permission when the platform offers it, then reuse it for the remaining documented steps.
4. The Codex approval dialog is the only acceptable user interaction for sandbox elevation. Never copy the failed command into chat for the user to run manually.
5. After approval, rerun the check and continue the remaining steps automatically. Only report a permission blocker when escalation is unavailable by policy, the user denies the platform request, or the elevated retry also fails; report that exact result without delegating the command.

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
Test-Path "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"                                                       # CLI installed?
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" whoami *> $null                                              # logged in? (exit code 0 = yes)
Select-String -Quiet '^GOALFY_UDS_API_KEY=' "$env:USERPROFILE\.codex\.env" -ErrorAction SilentlyContinue    # existing MCP setting present? (no value output)
& $codexCli plugin list | Select-String '^goalfydata@goalfydata\s+installed, enabled'                         # plugin installed?
```

- After the four commands, use Codex's protected local file access to compare `api_key` in `%USERPROFILE%\.goalfy\config.json` with the `GOALFY_UDS_API_KEY` value in `%USERPROFILE%\.codex\.env`. Keep both values only in the ephemeral file-edit operation; never display or persist them elsewhere. This is the fifth check
- All five pass → the user has a complete installation: **continue with Update**, asking the user for nothing
- Some pass → run only the steps for failing items; when `whoami` passes, skip Steps 1 and 3 because the credential is already saved locally. Run Step 5 whenever the fifth check fails
- None pass → perform the full installation from Step 1

Use the anchored plugin expression exactly. A broad search for `goalfydata` can falsely match the Windows username `goalfydata_test` in unrelated plugin paths.

### Step 1: Keep credentials out of the conversation

Do not request an API Key. Continue with CLI installation and let Step 3 open the verified browser setup.

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
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" whoami *> $null
```

Exit code 0 means already logged in; skip to Step 4 unless rotating the key. Always suppress both output streams so no credential prefix enters the conversation.

```powershell
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" login --api-url https://api.goalfydata.ai
```

If an exact install code was supplied, append `--install-code <code>`; otherwise omit it. The command opens `/connect/skill` with a public setup id and waits. Its private claim secret and resulting Key stay outside the browser URL and conversation.

If the browser does not open automatically, give the user the public URL printed by the command. While it waits, output:

```markdown
# ACTION REQUIRED: Finish connecting GoalfyData

**Complete the email verification in the GoalfyData page that just opened. You do not need to copy or send any API Key.**
```

Success: report `Login succeeded` and the account email; never report a Key or prefix. On timeout or expiry, run the same login command again to create a fresh link. A stale-key environment warning means Step 5 and a full restart are mandatory.

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

This is the same Codex environment configuration used before browser login was introduced; only the source of the value has changed. The source is now the `api_key` already saved by `uds-cli login` in `%USERPROFILE%\.goalfy\config.json`, never a value supplied in conversation.

Using Codex's existing protected local file read/edit capability:

1. Read `api_key` from `%USERPROFILE%\.goalfy\config.json` only within the ephemeral file-edit operation, without displaying or persisting it elsewhere.
2. Read `%USERPROFILE%\.codex\.env` if it exists; otherwise treat it as an empty text file.
3. Replace only the `GOALFY_UDS_API_KEY=` line with the saved value, or append the line when it is absent. Preserve every unrelated line.
4. Save the result to the same path as BOM-less UTF-8.
5. Re-read both files and compare the two values within the same ephemeral operation. Do not print or persist either value, its prefix, or the comparison operands.

Do not generate a PowerShell synchronization script or add another helper runtime for this step. Do not put the credential in a command, tool summary, user-facing message, log, or persistent Agent memory. If the two stored values already match, make no write and continue to Step 6.

### Step 6: Restart and verify

The MCP connection only takes effect after restarting Codex; you cannot verify it until the user has restarted. Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart Codex

1. **Quit Codex completely and reopen it**
2. **Then come back to this conversation and tell me you have restarted (any message works) — I will verify the connection myself**
```

After the user confirms the restart, verify the connection yourself — do not ask the user to check anything: confirm the 20 GoalfyData MCP tools (`uds_query`, `uds_dataset_manage`, etc.) are available, and run one dataset list (for example the `uds_dataset_get` MCP tool) as the read-only self-check; its result also decides the closing message in the Report below. Do not create, modify, or delete data merely to test connectivity.

If the self-check fails: repeat Step 5's protected in-memory comparison. If the values differ, repeat Steps 3 and 5; otherwise ask the user to fully restart again. Never request or display the Key.

### Report

After all steps, report with this template:

```
GoalfyData installation result:

[Done]
- uds-cli installed and logged in (version = the actual `uds-cli version` output, e.g. abc1234-yyyymmdd; account = the login email)
- Plugin goalfydata installed and enabled
- Existing MCP credential setting updated from the local uds-cli login without displaying it
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

1. Run Installation Step 3 again, **never skipped just because whoami passes**; the CLI opens a fresh verified browser setup and receives the replacement locally
2. Do not ask the user to copy or send the new Key
3. Update the MCP-side storage: run Installation Step 5, **unconditionally — never skipped because its check passes**. `%USERPROFILE%\.codex\.env` still holds the old key; without this update, MCP and new sessions keep using the old key after restart (whether login printed `WARNING: environment variable ...` only reflects the current session environment and must not be used as a reason to skip)
4. Consistency check: repeat Installation Step 5's protected in-memory comparison; never display either value or its prefix
5. Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart to activate the new API Key

**Quit Codex completely and reopen it.** The current session environment and the MCP connection are still using the old key; they only switch to the new key after a full restart.

**After restarting, if the old key has not been deleted yet, consider removing it at https://goalfydata.ai/settings to avoid mixing keys.**
```

Acceptance (in the user's new session after restart): `uds-cli whoami *> $null` exits 0 without surfacing credential output, and MCP tools no longer return unauthenticated.

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
| `cdn.goalfydata.ai` cannot be resolved or installer writes are denied | Treat it as a Codex sandbox restriction. Request scoped network/filesystem escalation and retry the command yourself; do not ask the user to run it in PowerShell |
| `irm` download fails after escalation | Check the network; the install script already enforces TLS 1.2 — if it still fails, report the exact error to the user |
| Browser setup expires or times out | Run Installation Step 3 again to create a fresh one-time link |
| MCP not connected | Check `GOALFY_UDS_API_KEY` in `%USERPROFILE%\.codex\.env`, then ask the user to fully restart Codex (you cannot restart on the user's behalf) |
| Tools return unauthenticated | Run Installation Steps 3 and 5 again without requesting or displaying a Key |
| login succeeds but subsequent commands return 401/unauthenticated | A stale key remains in the environment (which takes precedence over the saved login config). Follow "Rotating the API Key" and have the user restart |
| The `.env` key line exists but Codex reports `GOALFY_UDS_API_KEY` missing | The file may start with a UTF-8 BOM; save it as BOM-less UTF-8 with the protected local file editor, then fully restart |
| Exported in terminal but Desktop cannot connect | The Desktop app does not read terminal environment variables; the key must be in `%USERPROFILE%\.codex\.env` (Installation Step 5) |
| New terminals still cannot find uds-cli | User-level PATH not applied; redo the persistence check and write in Installation Step 2 |
