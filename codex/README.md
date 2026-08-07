# GoalfyData — Codex Plugin

OpenAI Codex plugin for connecting to the GoalfyData universal dataset service.

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

```bash
codex plugin marketplace add GoalfyAI/goalfydata
codex plugin add goalfydata@goalfydata
```

Codex Desktop users: paste the full content of [AGENTS.md](./AGENTS.md) into the chat — it is the agent-executable runbook; Codex will run the install commands and complete the configuration itself.

On Windows, use [AGENTS.windows.md](./AGENTS.windows.md) instead — it uses PowerShell commands and covers Windows-specific issues such as the WindowsApps `codex.exe` Access is denied error and GitHub clone failures.

## Authentication

GoalfyData still uses a Bearer credential internally, but users do not need to view or paste it. `uds-cli login` receives it through the one-time browser handoff and saves it to `~/.goalfy/config.json`. The agent-executable [AGENTS.md](./AGENTS.md) then writes the matching `~/.codex/.env` entry with a fixed local script that never prints the value. Restart Codex Desktop afterwards.

## Verification

After restarting Codex, confirm that `goalfydata-mcp` is connected and the tool list contains 20 tools (`uds_query`, `uds_dataset_manage`, etc.).

If connection fails:
- Re-run the non-printing credential equality check in [AGENTS.md](./AGENTS.md)
- If it differs, repeat its browser login and local sync steps
- Fully quit and restart Codex

## Update

### Plugin update

**Marketplace installation**: Refresh the marketplace index first, then reinstall:

```bash
codex plugin marketplace upgrade goalfydata
codex plugin remove goalfydata@goalfydata
codex plugin add goalfydata@goalfydata
```

### uds-cli update

```bash
uds-cli self-update
```

Both `already on the latest version` and `update succeeded: <old> → <new>` are normal; if it reports the API URL is not configured, run `uds-cli self-update --api-url https://api.goalfydata.ai` instead.

## Rotating the API Key

When the old key is deleted or needs rotation, complete all steps in order (logging in alone is not enough: environment variables take precedence over the saved login configuration, so a stale value keeps being used by both uds-cli and MCP).

Copy the setup text from the official integration page ( https://goalfydata.ai/integrations/codex ) and send it to your agent again. It will run browser login, sync the replacement credential locally without displaying it, and ask you to restart Codex.

> Why the restart is required: the configuration saved by login takes effect immediately, but the environment variables injected from the config file and the MCP connection only switch to the replacement credential after a full restart.

## Usage

Once the plugin is loaded, Codex automatically activates skills based on the task. You can also invoke manually:

```
/goalfydata Help me create a dataset
```
