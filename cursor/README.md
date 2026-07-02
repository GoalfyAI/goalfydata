# GoalfyData — Cursor Plugin

Cursor plugin for connecting to the GoalfyData universal dataset service.

## Features

- Build structured datasets (CSV/Excel/API/scripts)
- Data analysis (multi-turn SQL queries, aggregation, trend comparison)
- Import, query, and share datasets
- Configure scheduled sync
- Deploy data apps to the public internet

## Prerequisites

1. **GoalfyData API Token**: Create one at https://goalfydata.ai/settings
2. **uds-cli**:

   macOS / Linux:
   ```bash
   curl -fsSL https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.sh | sh
   source ~/.zshrc  # or source ~/.bashrc
   uds-cli login --token gfk_xxx --api-url https://api.goalfydata.ai
   ```

## Installation

Make sure you have completed the prerequisites above (Token creation + uds-cli installed and logged in) before installing.

### Option 1: Download ZIP

Download [goalfydata-cursor.zip](https://github.com/GoalfyAI/goalfydata/raw/main/cursor/goalfydata-cursor.zip), extract, and copy to the plugin directory:

```bash
unzip goalfydata-cursor.zip -d ~/.cursor/plugins/goalfydata
```

### Option 2: Git clone

```bash
git clone https://github.com/GoalfyAI/goalfydata.git
cp -r goalfydata/cursor ~/.cursor/plugins/goalfydata
```

After installation, restart Cursor and the plugin will automatically load the MCP server and Skills.

## Authentication

> **Cursor requires the token in plaintext**
>
> Cursor is a GUI application and does not read environment variables exported in `~/.zshrc` / `~/.bash_profile`. **Do not** use `${env:GOALFY_UDS_API_TOKEN}` -- it will resolve to empty and cause MCP connection failure. You **must** write the token in plaintext in `mcp.json`.

Open `mcp.json` in the plugin directory and replace `gfk_YOUR_TOKEN_HERE` with your actual token:

```json
{
  "mcpServers": {
    "goalfydata-mcp": {
      "type": "streamable-http",
      "url": "https://mcp.goalfydata.ai/mcp",
      "headers": {
        "Authorization": "Bearer gfk_YOUR_TOKEN_HERE"
      }
    }
  }
}
```

Security note: Plaintext tokens **must not** be committed to git.

## Verification

1. Cursor Settings -> MCP: `goalfydata-mcp` status shows connected (not Error)
2. In Chat, type "list my datasets" and the Agent will call the MCP tool to return results

## Update

### Plugin update

Re-download the latest [ZIP](https://github.com/GoalfyAI/goalfydata/raw/main/cursor/goalfydata-cursor.zip) and overwrite, or pull with git:

```bash
unzip -o goalfydata-cursor.zip -d ~/.cursor/plugins/goalfydata
```

After updating, fully quit and restart Cursor (MCP servers are only loaded at startup).

If you added the plugin via the Cursor Customize page, you can also click the **Refresh** button to reload, or enable **Auto Refresh** to automatically track repository updates.

### uds-cli update

```bash
uds-cli self-update
```

## Usage

Once the plugin is loaded, Cursor Agent automatically activates skills based on the task. You can also invoke manually:

```
/goalfydata Help me create a dataset
```
