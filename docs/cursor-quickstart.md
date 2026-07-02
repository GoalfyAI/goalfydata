# Cursor Quick Start

Get set up in 3 minutes and let Cursor help you build real-time data assets.

---

## Step 1 -- Get an API Token

Go to the [GoalfyData Console](https://goalfydata.ai/settings) to create an API Key (in the format `gfk_xxx`).

The plaintext key is only shown once at creation time. Save it in a secure location.

## Step 2 -- Install uds-cli

uds-cli is used for data plane operations (executing SQL, importing data, viewing table schemas).

macOS / Linux:
```bash
curl -fsSL https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.sh | sh
source ~/.zshrc  # or source ~/.bashrc
uds-cli login --token gfk_your_token --api-url https://api.goalfydata.ai
```

## Step 3 -- Install the Plugin

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

## Step 4 -- Configure Token

> Cursor is a GUI application and does not read environment variables exported in `~/.zshrc`. You must write the token in plaintext into `mcp.json`.

Open `~/.cursor/plugins/goalfydata/mcp.json` and replace `gfk_YOUR_TOKEN_HERE` with your actual token:

```json
{
  "mcpServers": {
    "goalfydata-mcp": {
      "type": "streamable-http",
      "url": "https://mcp.goalfydata.ai/mcp",
      "headers": {
        "Authorization": "Bearer gfk_your_actual_token"
      }
    }
  }
}
```

> Security note: Never commit plaintext tokens to git.

## Step 5 -- Restart Cursor

Fully quit and reopen Cursor to activate the plugin and MCP.

## Step 6 -- Verify

Go to Cursor Settings -> MCP: confirm that `goalfydata-mcp` shows as connected (not Error).

If it shows Error:
- Confirm that `mcp.json` contains your actual `gfk_` token in plaintext, not a placeholder
- Confirm the URL is correct: `https://mcp.goalfydata.ai/mcp`
- Fully quit and restart Cursor

## Getting Started

Once verification passes, tell the Agent directly in Cursor Chat what you want to do:

### Create a Dataset from a File

```
Create a dataset from this CSV file
```

### Pull Data from an API with Scheduled Sync

```
Create an e-commerce dataset with three tables: products, users, and orders
Pull data from the DummyJSON API, with automatic sync every day at 2 AM
```

### Query and Analyze Data

```
List my datasets
```

```
Analyze the orders table, with monthly sales trend statistics
```

### Develop a Data App

```
Build a dashboard app based on this dataset and deploy it to the public internet
```

---

## FAQ

### MCP Shows Error

99% of the time it is a token issue. Confirm that `mcp.json` contains your actual `gfk_` token in plaintext -- not `${env:...}` and not the `gfk_YOUR_TOKEN_HERE` placeholder.

### Skill Not Loaded

Confirm the plugin directory was fully copied to `~/.cursor/plugins/goalfydata/`, including all three parts: `.cursor-plugin/`, `mcp.json`, and `skills/`.

### uds-cli Command Not Found

After installation, you need to reopen your terminal (or run `source ~/.zshrc`) to refresh the PATH.

---

## Update

### Plugin Update

Re-download the latest [ZIP](https://github.com/GoalfyAI/goalfydata/raw/main/cursor/goalfydata-cursor.zip) and overwrite:

```bash
unzip -o goalfydata-cursor.zip -d ~/.cursor/plugins/goalfydata
```

After updating, fully quit and restart Cursor (MCP servers are only loaded at startup).

### uds-cli Update

```bash
uds-cli self-update
```

---

## Next Steps

- [Core Concepts](./concepts.md) -- Understand the Build / Run / Share architecture
- [FAQ](../FAQ.md) -- More answers to common questions
