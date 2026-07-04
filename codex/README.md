# GoalfyData — Codex Plugin

OpenAI Codex plugin for connecting to the GoalfyData universal dataset service.

## Features

- Build structured datasets (CSV/Excel/API/scripts)
- Data analysis (multi-turn SQL queries, aggregation, trend comparison)
- Import, query, and share datasets
- Configure scheduled sync
- Deploy data apps to the public internet

## Prerequisites

1. **GoalfyData API Key**: Create one at https://goalfydata.ai/settings
2. **uds-cli**:

   macOS / Linux:
   ```bash
   curl -fsSL https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.sh | sh
   # if "command not found": use "$HOME/.goalfy/bin/uds-cli" instead of uds-cli
   uds-cli login --api-key gfk_xxx --api-url https://api.goalfydata.ai
   ```

## Installation

Make sure you have completed the prerequisites above (API Key creation + uds-cli installed and logged in) before installing.

```bash
codex plugin marketplace add GoalfyAI/goalfydata
codex plugin add goalfydata@goalfydata
```

Codex Desktop users: paste the full content of [AGENTS.md](./AGENTS.md) into the chat — it is the agent-executable runbook; Codex will run the install commands and complete the configuration itself.

## Authentication

Codex Desktop is an Electron application and does not inherit terminal environment variables. You need to configure the API Key in `~/.codex/.env`:

```bash
# ~/.codex/.env
GOALFY_UDS_API_KEY=gfk_your_api_key_here
```

Restart Codex Desktop after configuration for it to take effect.

Codex CLI (terminal) can also use standard shell export:

```bash
export GOALFY_UDS_API_KEY="gfk_your_api_key_here"
```

MCP tools and uds-cli share the same API Key.

## Verification

After restarting Codex, confirm that `goalfydata-mcp` is connected and the tool list contains 20 tools (`uds_query`, `uds_dataset_manage`, etc.).

If connection fails:
- Confirm `GOALFY_UDS_API_KEY` is configured in `~/.codex/.env`
- Confirm the API Key is valid (verify in the console)
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

## Rotating the API Key

When the old key is deleted or needs rotation, complete all steps in order (logging in alone is not enough: environment variables take precedence over the saved login configuration, so a stale value keeps being used by both uds-cli and MCP).

The easiest way: copy the setup text from the official integration page ( https://goalfydata.ai/integrations/codex ) and send it to your agent again and it handles everything. Manual steps:

1. Delete the old key and create/copy a new one in the [GoalfyData console](https://goalfydata.ai/settings)
2. Log in again: `uds-cli login --api-key gfk_your_new_key --api-url https://api.goalfydata.ai`
3. Update the value of `GOALFY_UDS_API_KEY` in `~/.codex/.env` to the new key
4. Quit Codex completely and reopen it

## Usage

Once the plugin is loaded, Codex automatically activates skills based on the task. You can also invoke manually:

```
/goalfydata Help me create a dataset
```
