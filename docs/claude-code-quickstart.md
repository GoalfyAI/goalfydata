# Claude Code Quick Start

Get set up in 3 minutes and let Claude Code help you build real-time data assets.

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

Windows (PowerShell):
```powershell
irm https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.ps1 | iex
# Reopen PowerShell so PATH takes effect, then:
uds-cli login --token gfk_your_token --api-url https://api.goalfydata.ai
```

## Step 3 -- Install the Plugin

### Recommended: Install via Marketplace

Installing from the marketplace automatically handles the plugin structure, MCP configuration, and Skill loading -- no need to manually copy files.

```bash
claude plugin marketplace add GoalfyAI/goalfydata
claude plugin install goalfydata@goalfydata
```

### Alternative: Git clone + local marketplace

Clone the repository and add it as a local marketplace — this goes through the plugin mechanism, so both MCP and Skill load correctly:

```bash
git clone https://github.com/GoalfyAI/goalfydata.git
claude plugin marketplace add ./goalfydata
claude plugin install goalfydata@goalfydata
```

> **Do NOT copy files into `~/.claude/skills/` manually.** The `.mcp.json` inside a skills directory is never read by Claude Code, so the MCP connection would silently fail.

## Step 4 -- Configure Token

Add your Token in the `env` section of `~/.claude/settings.json`:

```json
{
  "env": {
    "GOALFY_UDS_API_TOKEN": "gfk_your_token"
  }
}
```

> This step is required -- otherwise the MCP connection will fail. When launching Claude Code from a desktop app or IDE, shell environment variables are not read. The token must be configured via settings.json.

## Step 5 -- Restart Claude Code

Fully quit and reopen Claude Code to activate the plugin and MCP.

## Step 6 -- Verify

Type `/mcp` in Claude Code and confirm that `goalfydata-mcp` shows as connected with 20 tools.

If it shows as failed:
- Confirm that `GOALFY_UDS_API_TOKEN` is configured in `~/.claude/settings.json`
- Confirm the token has a valid `gfk_` prefix
- Fully quit and restart Claude Code

## Getting Started

Once verification passes, simply tell Claude Code what you want to do:

### Create a Dataset from a File

```
Create a dataset from this Excel file
```

### Pull Data from an API with Scheduled Sync

```
Create an e-commerce dataset with 3 tables:
- products: pull from https://dummyjson.com/products
- users: pull from https://dummyjson.com/users
- orders: pull from https://dummyjson.com/carts
Set up automatic sync every day at 2 AM.
```

### Query and Analyze Existing Datasets

```
List my datasets
```

```
Analyze the orders table trends, with monthly sales statistics
```

### Develop a Data App

```
Based on this e-commerce dataset, build a dashboard app and deploy it to the public internet
```

### Share a Dataset

```
Share this dataset with xxx@example.com
```

---

## FAQ

### MCP Shows Error / Not Connected

1. Check whether `GOALFY_UDS_API_TOKEN` exists in `~/.claude/settings.json`
2. Confirm the token is valid (verify in the console)
3. Fully quit and restart Claude Code

### uds-cli Command Not Found

After installation, you need to reopen your terminal (or run `source ~/.zshrc`) to refresh the PATH.

### Plugin Installation Fails with "source type not supported"

Run `claude plugin marketplace update goalfydata` to update the cache and try again.

---

## Update

### Plugin Update

**Marketplace installation**: Marketplace plugins auto-update on startup. Manual update:

```bash
claude plugin update goalfydata@goalfydata
```

**Local marketplace installation**: Pull the latest changes and refresh the marketplace:

```bash
cd goalfydata && git pull
claude plugin marketplace update goalfydata
```

After updating, run `/reload-plugins` or restart Claude Code.

### uds-cli Update

```bash
uds-cli self-update
```

---

## Next Steps

- [Core Concepts](./concepts.md) -- Understand the Build / Run / Share architecture
- [Full SKILL Documentation](../claude-code/skills/goalfydata/SKILL.md) -- Detailed tools and execution flows
- [FAQ](../FAQ.md) -- More answers to common questions
