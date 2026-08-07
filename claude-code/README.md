# GoalfyData — Claude Code Plugin

Claude Code plugin for connecting to the GoalfyData universal dataset service.

## Features

- Build structured datasets (CSV/Excel/API/scripts)
- Data analysis (multi-turn SQL queries, aggregation, trend comparison)
- Import, query, and share datasets
- Configure scheduled sync
- Deploy data apps to the public internet

## Prerequisites

1. **GoalfyData account**: The browser setup can sign in or register with email verification.
2. **uds-cli**:

   macOS / Linux:
   ```bash
   curl -fsSL https://cdn.goalfydata.ai/dataset-uds/install.sh | sh
   # if "command not found": use "$HOME/.goalfy/bin/uds-cli" instead of uds-cli
   uds-cli login --api-url https://api.goalfydata.ai
   ```

## Installation

Make sure uds-cli is installed and the browser login has completed before installing.

### Option 1: Via marketplace (recommended)

Marketplace installation automatically handles plugin structure, MCP configuration, and Skill loading -- no need to manually copy files.

```bash
claude plugin marketplace add GoalfyAI/goalfydata
claude plugin install goalfydata@goalfydata
```

### Option 2: Git clone + local marketplace

Clone the repository and add it as a local marketplace — this goes through the plugin mechanism, so both MCP and Skill load correctly:

```bash
git clone https://github.com/GoalfyAI/goalfydata.git
claude plugin marketplace add ./goalfydata
claude plugin install goalfydata@goalfydata
```

> **Do NOT copy files into `~/.claude/skills/` manually.** The `.mcp.json` inside a skills directory is never read by Claude Code, so the MCP connection would silently fail.

### Option 3: Local development testing

```bash
claude --plugin-dir ./claude-code
```

After installation, restart Claude Code and the plugin will automatically load the MCP server.

## Authentication

GoalfyData still uses a Bearer credential internally, but users do not need to view or paste it. `uds-cli login` receives it through the one-time browser handoff and saves it to `~/.goalfy/config.json`. The agent-executable [AGENTS.md](./AGENTS.md) then updates the existing `~/.claude/settings.json` environment setting through Claude Code's protected local file access, without adding a helper runtime or displaying the value.

## Verification

After restarting Claude Code, type `/mcp` and confirm that `goalfydata-mcp` shows status connected + 20 tools.

If connection fails:
- Re-run the protected in-memory credential comparison in [AGENTS.md](./AGENTS.md)
- If it differs, repeat its browser login and local sync steps
- Fully quit and restart Claude Code

## Update

### Plugin update

**Marketplace installation (auto-update)**: Marketplace plugins automatically check for updates when Claude Code starts. You can also update manually:

```bash
claude plugin update goalfydata@goalfydata
```

**Local marketplace installation**: Pull the latest changes and refresh the marketplace:

```bash
cd goalfydata && git pull
claude plugin marketplace update goalfydata
```

After updating, run `/reload-plugins` in your session to reload, or restart Claude Code.

### uds-cli update

```bash
uds-cli self-update
```

Both `already on the latest version` and `update succeeded: <old> → <new>` are normal; if it reports the API URL is not configured, run `uds-cli self-update --api-url https://api.goalfydata.ai` instead.

## Rotating the API Key

When the old key is deleted or needs rotation, complete all steps in order (logging in alone is not enough: environment variables take precedence over the saved login configuration, so a stale value keeps being used by both uds-cli and MCP).

Copy the setup text from the official integration page ( https://goalfydata.ai/integrations/claude-code ) and send it to your agent again. It will run browser login, sync the replacement credential locally without displaying it, and ask you to restart Claude Code.

> Why the restart is required: the configuration saved by login takes effect immediately, but the environment variables injected from the config file and the MCP connection only switch to the replacement credential after a full restart.

## Usage

Once the plugin is loaded, Claude Code automatically activates skills based on the task. You can also invoke manually:

```
/goalfydata Help me create a dataset
```
