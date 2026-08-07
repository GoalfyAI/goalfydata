# GoalfyData Install & Update Guide — Claude Code (Agent Edition)

While executing this guide, you must follow these rules:

1. Only run the commands listed here; only write to the installer-owned `~/.goalfy/` directory, the matching shell rc PATH line described in Step 2, `~/.claude/settings.json` (merge-write), and the Claude Code plugin directory
2. Never ask the user to create, copy, paste, or send an API Key; `uds-cli login` opens the verified setup page and receives the credential locally
3. Never print or read the plaintext Key into the conversation. After browser login, use Claude Code's existing protected local file access to copy the saved `api_key` from `~/.goalfy/config.json` into the existing Claude Code environment setting; do not require Python, Node.js, `jq`, or another helper runtime
4. If the copied instructions or setup message contain an install code matching `^(inst|ref)_[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8,12}$`, preserve it exactly: append it as `gf_ref` to every `goalfydata.ai` page URL while keeping existing query parameters, and pass it to `uds-cli login` with `--install-code`. Do not append it to GitHub, CDN, or `api.goalfydata.ai` URLs. If no code was supplied, omit it. Never use an install code as a credential. This rule overrides static page URLs in the templates below
5. Whenever the user must act or provide something, output the corresponding ACTION REQUIRED template: as normal body text, never inside a code block or blockquote; the level-1 heading and bold must be preserved and never rewritten as plain sentences. The templates are written in English — when the user converses in another language, translate the content and keep the structure and emphasis intact
6. Do not declare success until the plugin is enabled, Claude Code has been restarted, the GoalfyData MCP tools (20, such as `uds_query` and `uds_dataset_manage`) are loaded, and a read-only MCP request succeeds
7. Run every installation, update, login, and configuration command yourself. Never send shell commands to the user or ask them to open Terminal

Every step starts with a check command: skip steps that are already done; re-running any step is safe.

---

## Installation

### Mandatory sandbox and permission handling

This conversation is running inside Claude Code's sandbox and permission system, not inside the user's later macOS or Linux terminal. The current session has a built-in permission request path for commands that need network access or writes outside the workspace.

1. Run every check and command in this guide yourself.
2. Treat `Could not resolve host: cdn.goalfydata.ai`, other blocked network access, or a write denial under `~/.goalfy`, the selected shell rc file, `~/.claude/settings.json`, or the plugin directory as a sandbox restriction first. It is not evidence that the website is down, the API Key is invalid, or the user's normal network is broken.
3. When a required Bash command is blocked by the sandbox, retry it yourself with the Bash tool's `dangerouslyDisableSandbox: true` parameter so Claude Code uses its normal permission flow. Issue at most one sandbox-elevation prompt for one installation attempt: request the narrowest sufficient reusable command or domain permission offered by the platform, then reuse it for the remaining documented steps.
4. The platform approval dialog is the only acceptable user interaction for sandbox elevation. Never copy the failed command into chat for the user to run manually.
5. After approval, rerun the check and continue the remaining steps automatically. Only report a permission blocker when unsandboxed commands are disabled by policy, the user denies the platform request, or the elevated retry also fails; report that exact result without delegating the command.

### Step 0: Detect the current state (install vs update)

Start with the following four check commands — no user interaction. Then complete the protected comparison below and route by all five results:

```bash
command -v uds-cli || ls "$HOME/.goalfy/bin/uds-cli"                 # CLI installed?
"$HOME/.goalfy/bin/uds-cli" whoami >/dev/null 2>&1                    # logged in? (exit code 0 = yes)
grep -q '"GOALFY_UDS_API_KEY"' "$HOME/.claude/settings.json"         # existing MCP setting present? (no value output)
claude plugin list | grep goalfydata                                  # plugin installed?
```

- After the four commands, use Claude Code's protected local file access to compare `api_key` in `~/.goalfy/config.json` with `env.GOALFY_UDS_API_KEY` in `~/.claude/settings.json`. Keep both values only in the ephemeral file-edit operation; never display or persist them elsewhere. This is the fifth check
- All five pass → the user has a complete installation: **continue with Update**, asking the user for nothing
- Some pass → run only the steps for the failing items; when `whoami` passes, skip Steps 1 and 3 because the credential is already saved locally. Run Step 5 whenever the fifth check fails
- None pass → full installation from Step 1

### Step 1: Keep credentials out of the conversation

Do not request an API Key. Continue with CLI installation and let Step 3 open the verified browser setup.

### Step 2: Install uds-cli

Check: `command -v uds-cli || ls "$HOME/.goalfy/bin/uds-cli"` — if either produces output, it is installed. When already installed, **do not skip directly** — update to the latest version first, then proceed to Step 3:

```bash
"$HOME/.goalfy/bin/uds-cli" self-update --api-url https://api.goalfydata.ai
```

Both `already on the latest version` and `update succeeded: <old> → <new>` are normal.

If not installed, install it:

```bash
curl -fsSL https://cdn.goalfydata.ai/dataset-uds/install.sh | sh
```

Success: output `uds-cli <version> installed to <absolute-home-path>/.goalfy/bin/uds-cli`.

If the `uds-cli` command is not visible after installing, call it by absolute path `"$HOME/.goalfy/bin/uds-cli"` from then on — do not reinstall.

After installing, check whether the PATH is persisted (the install script writes it to shell config files automatically; this is a fallback check so that future sessions can use `uds-cli` directly):

```bash
for file in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  [ -f "$file" ] || continue
  grep -l "\.goalfy/bin" "$file" || true
done
```

Output means it is persisted. If there is no output, you **must** write the persistent configuration — otherwise the user's future sessions still cannot find `uds-cli`.

Decide which file to write based on the user's environment: check the default shell (`echo $SHELL`) and which config files already exist, then append `export PATH="$HOME/.goalfy/bin:$PATH"` to the matching one (zsh → `~/.zshrc`; bash → `~/.bash_profile` on macOS, `~/.bashrc` on Linux). Prefer appending to files that already exist; do not create unnecessary config files.

After writing, run the grep check above again; this step is complete only when it produces output. If it still produces nothing, report it honestly — do not skip.

### Step 3: Log in

Check: `"$HOME/.goalfy/bin/uds-cli" whoami >/dev/null 2>&1` — exit code 0 means already logged in; skip to Step 4. Always suppress both output streams so no credential prefix enters the conversation.

```bash
"$HOME/.goalfy/bin/uds-cli" login --api-url https://api.goalfydata.ai
```

If an exact install code was supplied, append `--install-code <code>`; otherwise omit it. The command opens `/connect/skill` with a public setup id and waits. Its private claim secret and resulting Key stay outside the browser URL and conversation.

If the browser does not open automatically, give the user the public URL printed by the command. While it waits, output:

```markdown
# ACTION REQUIRED: Finish connecting GoalfyData

**Complete the email verification in the GoalfyData page that just opened. You do not need to copy or send any API Key.**
```

Success: report `Login succeeded` and the account email; never report a Key or prefix. On timeout or expiry, run the same login command again to create a fresh link.

### Step 4: Install the plugin

Check: `claude plugin list | grep goalfydata` — if it produces output, skip to Step 5.

```bash
claude plugin marketplace add GoalfyAI/goalfydata
claude plugin install goalfydata@goalfydata
```

On failure: for `source type not supported`, run `claude plugin marketplace update goalfydata` and retry.

### Step 5: Configure the API Key

This is the same Claude Code environment configuration used before browser login was introduced; only the source of the value has changed. The source is now the `api_key` already saved by `uds-cli login` in `~/.goalfy/config.json`, never a value supplied in conversation.

Using Claude Code's existing protected local file read/edit capability:

1. Read `api_key` from `~/.goalfy/config.json` only within the ephemeral file-edit operation, without displaying or persisting it elsewhere.
2. Read `~/.claude/settings.json` if it exists; otherwise start with an empty JSON object.
3. Merge the saved value into the existing `env.GOALFY_UDS_API_KEY` field, preserving every unrelated setting. Never overwrite the complete file with a template.
4. Save valid JSON to the same path and keep the file private to the user.
5. Re-read both files and compare the two values within the same ephemeral operation. Do not print or persist either value, its prefix, or the comparison operands.

Do not use Python, Node.js, `jq`, or another helper runtime for this step. Do not put the credential in a shell command, tool summary, user-facing message, log, or persistent Agent memory. If the two stored values already match, make no write and continue to Step 6.

### Step 6: Restart and verify

The MCP connection only takes effect after a restart; you cannot verify it until the user has restarted. Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart Claude Code

1. **Quit Claude Code completely and reopen it**
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
- Plugin goalfydata installed
- Existing MCP credential setting updated from the local uds-cli login without displaying it
- 20 MCP tools loaded and a read-only request succeeded

[Action required from you]
- (none / restart Claude Code and tell me when it is done — I will verify the connection)

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

### Step 1: Update the plugin

```bash
# marketplace install (default)
claude plugin update goalfydata@goalfydata

# local git clone install
cd goalfydata && git pull && claude plugin marketplace update goalfydata
```

### Step 2: Update uds-cli

```bash
"$HOME/.goalfy/bin/uds-cli" self-update
```

Success: output `already on the latest version` or `update succeeded: <old> → <new>`.

### Step 3: Restart to take effect

Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart to take effect

**Run `/reload-plugins` in the session, or quit Claude Code completely and reopen it — the update only takes effect afterwards.**
```

---

## Rotating the API Key

Run this section when the user wants to rotate the API Key (or the old key has been deleted/invalidated). Understand the key's activation model first — otherwise the rotation silently fails:

- The key lives in two places: `~/.goalfy/config.json` (written by login, read by uds-cli) and the `env` block of `~/.claude/settings.json` (used for the MCP request header, and also injected into the agent's session environment)
- Precedence: environment variables override the config — if the `env` block of `~/.claude/settings.json` is not updated, the stale environment value overrides the newly saved key
- Activation timing: the config takes effect immediately; the `env` block of `~/.claude/settings.json` and the session environment only take effect **after a full restart**

Execute in order (skip the Step 0 routing in the rotation case):

1. Run Installation Step 3 again, **never skipped just because whoami passes**; the CLI opens a fresh verified browser setup and receives the replacement locally
2. Do not ask the user to copy or send the new Key
3. Update the MCP-side storage: run Installation Step 5, **unconditionally — never skipped because its check passes**. `~/.claude/settings.json` still holds the old key; without this update, MCP and new sessions keep using the old key after restart (whether login printed `WARNING: environment variable ...` only reflects the current session environment and must not be used as a reason to skip)
4. Consistency check: repeat Installation Step 5's protected in-memory comparison; never display either value or its prefix
5. Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart to activate the new API Key

**Quit Claude Code completely and reopen it.** The current session environment and the MCP connection are still using the old key; they only switch to the new key after a full restart.

**After restarting, if the old key has not been deleted yet, consider removing it at https://goalfydata.ai/settings to avoid mixing keys.**
```

Acceptance (in the user's new session after restart): `uds-cli whoami >/dev/null 2>&1` exits 0 without surfacing credential output, and MCP tools no longer return unauthenticated.

If the user no longer has this guide, output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Get the setup text again

**Open the GoalfyData integration page: https://goalfydata.ai/integrations/claude-code**

**Copy the setup text on the page and send it to me again — I will complete every step automatically, including rotating the API Key.**
```

---

## Troubleshooting

| Symptom | Handling |
|---|---|
| `command not found: uds-cli` | Use the absolute path `"$HOME/.goalfy/bin/uds-cli"`; only reinstall if the file does not exist (Installation Step 2) |
| `Could not resolve host: cdn.goalfydata.ai` or installer writes are denied | Treat it as a Claude Code sandbox restriction. Retry the required Bash command with `dangerouslyDisableSandbox: true` through the platform permission flow; do not ask the user to run it in Terminal |
| Browser setup expires or times out | Run Installation Step 3 again to create a fresh one-time link |
| `/mcp` shows not connected | Check `GOALFY_UDS_API_KEY` in settings.json, then ask the user to fully restart (you cannot restart on the user's behalf) |
| Tools return unauthenticated | Run Installation Steps 3 and 5 again without requesting or displaying a Key |
| Plugin update not taking effect | Ask the user to run `/reload-plugins` or fully restart |
| login succeeds but subsequent commands return 401/unauthenticated | A stale key remains in the environment (which takes precedence over the saved login config). Follow "Rotating the API Key" and have the user restart |
