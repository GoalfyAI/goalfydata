# GoalfyData Install & Update Guide — Claude Code (Agent Edition)

While executing this guide, you must follow these rules:

1. Only run the commands listed here; only write to `~/.claude/settings.json` (merge-write) and the Claude Code plugin directory
2. When mentioning obtaining or verifying the API Key to the user, include the settings link https://goalfydata.ai/settings
3. The API Key must come from the user — never fabricate one or proceed with a placeholder

Every step starts with a check command: skip steps that are already done; re-running any step is safe.

---

## Installation

### Step 1: Confirm the API Key

Output the contents of the template below to the user word for word (as normal body text — not inside a code block or blockquote; the level-1 heading and bold must be preserved, never rewritten as plain sentences), and continue only after receiving the key:

```markdown
# ACTION REQUIRED: Provide your GoalfyData API Key

**Do you already have a GoalfyData API Key (shaped like `gfk_xxx`)? If so, send it to me directly.**

**If not, create one in GoalfyData: https://goalfydata.ai/settings ("Settings → API Key"; the plaintext is shown only once at creation — store it safely). No account yet? Open https://goalfydata.ai to sign up.**

Send me the API Key once created, and I will finish the remaining steps.
```

### Step 2: Install uds-cli

Check: `command -v uds-cli || ls "$HOME/.goalfy/bin/uds-cli"` — if either produces output, it is installed. When already installed, **do not skip directly** — update to the latest version first, then proceed to Step 3:

```bash
"$HOME/.goalfy/bin/uds-cli" self-update --api-url https://api.goalfydata.ai
```

Both `already on the latest version` and `update succeeded: <old> → <new>` are normal.

If not installed, install it:

```bash
curl -fsSL https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.sh | sh
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

Success: output `Login succeeded` and `API Key: gfk_xxx...`.

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
- Verify after writing: the file is still valid JSON (`python3 -c "import json; json.load(open('<path>'))"`), and grep finds `GOALFY_UDS_API_KEY`

### Step 6: Restart and verify

The MCP connection only takes effect after a restart; you cannot verify it in the current session — the user must do this. Output the contents of the template below to the user word for word (as normal body text; the level-1 heading and bold must be preserved):

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
- uds-cli installed and logged in (version x.y.z, account xxx@example.com)
- Plugin goalfydata installed
- API Key written to ~/.claude/settings.json

[Action required from you]
- Restart Claude Code and type /mcp to verify the connection (see above)

[Not completed]
- (none / list reasons)

From here, just describe what you want, e.g. "Build a dataset from this Excel file."
More usage at https://goalfydata.ai .
```

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

Output the contents of the template below to the user word for word (as normal body text; the level-1 heading and bold must be preserved):

```markdown
# ACTION REQUIRED: Restart to take effect

**Run `/reload-plugins` in the session, or quit Claude Code completely and reopen it — the update only takes effect afterwards.**
```

---

## Rotating the API Key

When the user wants to rotate the API Key (or the old key has been deleted/invalidated), no separate procedure is needed: **re-run the Installation flow of this guide** from Step 1 — the flow is idempotent and will naturally direct the user to create a new key, log in again, update the MCP-side storage, and prompt for a restart.

If the user no longer has this guide, output the contents of the template below to the user word for word (as normal body text; the level-1 heading and bold must be preserved):

```markdown
# ACTION REQUIRED: Get the setup text again

**Open the GoalfyData integration page: https://goalfydata.ai/integrations/claude-code**

**Copy the setup text on the page and send it to me again — I will complete every step automatically, including rotating the API Key.**
```

Two exceptions that override the idempotent skip rules in the rotation case:

- Step 3 (login) must NOT be skipped just because whoami succeeds — the old key may not be deleted yet; log in again with the new key
- If login prints `WARNING: environment variable ...`, Step 5 is mandatory, and the user must restart afterwards

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
| login succeeds but subsequent commands return 401/unauthenticated | A stale key remains in the environment (which takes precedence over the saved login config). Re-run the Installation flow per "Rotating the API Key" and have the user restart |
