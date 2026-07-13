# GoalfyData Install & Update Guide — Claude Code (Agent Edition)

While executing this guide, you must follow these rules:

1. Only run the commands listed here; only write to `~/.claude/settings.json` (merge-write) and the Claude Code plugin directory
2. For first-time setup, send the user to https://goalfydata.ai/connect/skill; https://goalfydata.ai/settings is only the manual alternative for creating or managing a Key
3. The API Key must be the exact `gfk_` value sent by the user or returned in the setup message — never fabricate, rewrite, or substitute a placeholder
4. If the copied instructions or setup message contain an install code matching `^(inst|ref)_[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8,12}$`, preserve it exactly: append it as `gf_ref` to every `goalfydata.ai` page URL while keeping existing query parameters, and pass it to `uds-cli login` with `--install-code`. Do not append it to GitHub, CDN, or `api.goalfydata.ai` URLs. If no code was supplied, omit it. Never use an install code as a credential. This rule overrides static page URLs in the templates below
5. Whenever the user must act or provide something, output the corresponding ACTION REQUIRED template: as normal body text, never inside a code block or blockquote; the level-1 heading and bold must be preserved and never rewritten as plain sentences. The templates are written in English — when the user converses in another language, translate the content and keep the structure and emphasis intact

Every step starts with a check command: skip steps that are already done; re-running any step is safe.

---

## Installation

### Step 0: Detect the current state (install vs update)

The following are all check commands — no user interaction. Route by the result:

```bash
command -v uds-cli || ls "$HOME/.goalfy/bin/uds-cli"   # CLI installed?
"$HOME/.goalfy/bin/uds-cli" whoami                      # logged in? (exit code 0 = yes)
grep GOALFY_UDS_API_KEY "$HOME/.claude/settings.json" # MCP-side key configured?
claude plugin list | grep goalfydata                   # plugin installed?
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
grep -l "\.goalfy/bin" "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" 2>/dev/null
```

Output means it is persisted. If there is no output, you **must** write the persistent configuration — otherwise the user's future sessions still cannot find `uds-cli`.

Decide which file to write based on the user's environment: check the default shell (`echo $SHELL`) and which config files already exist, then append `export PATH="$HOME/.goalfy/bin:$PATH"` to the matching one (zsh → `~/.zshrc`; bash → `~/.bash_profile` on macOS, `~/.bashrc` on Linux). Prefer appending to files that already exist; do not create unnecessary config files.

After writing, run the grep check above again; this step is complete only when it produces output. If it still produces nothing, report it honestly — do not skip.

### Step 3: Log in

Check: `"$HOME/.goalfy/bin/uds-cli" whoami` — exit code 0 means already logged in; skip to Step 4.

```bash
"$HOME/.goalfy/bin/uds-cli" login --api-key <user-provided-key> --api-url https://api.goalfydata.ai
```

Replace `<user-provided-key>` with the exact API Key received from the user — never execute the command with an example value or placeholder. If an exact install code was supplied, also pass it with `--install-code <code>`; otherwise omit that argument.

Success: report the real `Login succeeded` output and the masked API Key value printed by uds-cli.

On failure: `unknown flag: --api-key` means an outdated CLI — run `"$HOME/.goalfy/bin/uds-cli" self-update` and retry; `API Key validation failed` means an invalid key — return to Step 1.

### Step 4: Install the plugin

Check: `claude plugin list | grep goalfydata` — if it produces output, skip to Step 5.

```bash
claude plugin marketplace add GoalfyAI/goalfydata
claude plugin install goalfydata@goalfydata
```

On failure: for `source type not supported`, run `claude plugin marketplace update goalfydata` and retry.

### Step 5: Configure the API Key

Check: `grep GOALFY_UDS_API_KEY "$HOME/.claude/settings.json"` — if present with the correct value, skip to Step 6.

Goal: add (or update) the following key inside `env` in `~/.claude/settings.json`, keeping everything else in the file intact:

```json
{
  "env": {
    "GOALFY_UDS_API_KEY": "<user-provided-key>"
  }
}
```

Requirements:
- This file holds the user's entire Claude Code configuration; corrupting it makes Claude Code unusable. Read the existing content first and merge — never overwrite the file wholesale
- If the file does not exist, create it with the structure above
- Verify after writing: the file is still valid JSON (`python3 -c "import json, os; json.load(open(os.path.expanduser('~/.claude/settings.json')))"`), and grep finds `GOALFY_UDS_API_KEY`

### Step 6: Restart and verify

The MCP connection only takes effect after a restart; you cannot verify it in the current session — the user must do this. Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart and verify MCP

1. **Quit Claude Code completely and reopen it**
2. **After restarting, type `/mcp` and confirm `goalfydata-mcp` shows connected + 20 tools**

If it fails: confirm `GOALFY_UDS_API_KEY` exists in `~/.claude/settings.json` and the key shows as valid at https://goalfydata.ai/settings , then fully restart again.
```

### Report

After all steps, report with this template:

```
GoalfyData installation result:

[Done]
- uds-cli installed and logged in (version = the actual `uds-cli version` output, e.g. abc1234-yyyymmdd; account = the login email)
- Plugin goalfydata installed
- API Key written to ~/.claude/settings.json

[Action required from you]
- Restart Claude Code and type /mcp to verify the connection (see above)

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

1. Direct the user to create a new key: run Installation Step 1 (output the key-request template)
2. Log in again with the new key: run Installation Step 3, **never skipped just because whoami passes** (the old key may not be deleted yet)
3. Update the MCP-side storage: run Installation Step 5, **unconditionally — never skipped because its check passes**. `~/.claude/settings.json` still holds the old key; without this update, MCP and new sessions keep using the old key after restart (whether login printed `WARNING: environment variable ...` only reflects the current session environment and must not be used as a reason to skip)
4. Consistency check: confirm both `~/.goalfy/config.json` and `~/.claude/settings.json` now hold the new key (compare the first characters after gfk_)
5. Output the template below to the user word for word:

```markdown
# ACTION REQUIRED: Restart to activate the new API Key

**Quit Claude Code completely and reopen it.** The current session environment and the MCP connection are still using the old key; they only switch to the new key after a full restart.

**After restarting, if the old key has not been deleted yet, consider removing it at https://goalfydata.ai/settings to avoid mixing keys.**
```

Acceptance (in the user's new session after restart): `uds-cli whoami` shows the new key prefix, and MCP tools no longer return unauthenticated.

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
| `unknown flag: --api-key` | Outdated CLI; run `self-update` first, then retry |
| login reports validation failed | Direct the user to https://goalfydata.ai/settings to verify the key, recreating it if necessary |
| `/mcp` shows not connected | Check `GOALFY_UDS_API_KEY` in settings.json, then ask the user to fully restart (you cannot restart on the user's behalf) |
| Tools return unauthenticated | Key missing or invalid; return to Installation Step 1 |
| Plugin update not taking effect | Ask the user to run `/reload-plugins` or fully restart |
| login succeeds but subsequent commands return 401/unauthenticated | A stale key remains in the environment (which takes precedence over the saved login config). Follow "Rotating the API Key" and have the user restart |
