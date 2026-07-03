# Codex Quick Start

Get set up in 3 minutes and let Codex help you build real-time data assets.

> Prefer automated install? Send [AGENTS.md](../codex/AGENTS.md) to your agent and it handles everything.

---

## Step 1 -- Get an API Key

Go to the [GoalfyData Console](https://goalfydata.ai/settings) to create an API Key (in the format `gfk_xxx`).

The plaintext key is only shown once at creation time. Save it in a secure location.

## Step 2 -- Install uds-cli

uds-cli is used for data plane operations (executing SQL, importing data, viewing table schemas).

macOS / Linux:
```bash
curl -fsSL https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.sh | sh
# if "command not found": use "$HOME/.goalfy/bin/uds-cli" instead of uds-cli
uds-cli login --api-key gfk_your_api_key --api-url https://api.goalfydata.ai
```

## Step 3 -- Install the Plugin

Codex CLI:
```bash
codex plugin marketplace add GoalfyAI/goalfydata
codex plugin add goalfydata@goalfydata
```

Codex Desktop: Paste the full content of [AGENTS.md](../codex/AGENTS.md) into the chat — it is the agent-executable runbook; Codex will run the install commands and complete the configuration itself.

## Step 4 -- Configure API Key

Codex Desktop is an Electron application and does not inherit terminal environment variables. You need to write the API Key into `~/.codex/.env`:

```bash
# ~/.codex/.env
GOALFY_UDS_API_KEY=gfk_your_api_key
```

Restart Codex Desktop after configuration for changes to take effect.

Codex CLI (terminal) can also use a standard shell export:

```bash
export GOALFY_UDS_API_KEY="gfk_your_api_key"
```

> This step is required -- otherwise the MCP connection will fail due to authentication errors.

## Step 5 -- Restart Codex

Fully quit and reopen Codex to activate the plugin and MCP.

## Step 6 -- Verify

In Codex, confirm that `goalfydata-mcp` is connected and the tool list contains 20 tools (`uds_query`, `uds_dataset_manage`, etc.).

If the connection fails:
- Confirm that `GOALFY_UDS_API_KEY` is configured in `~/.codex/.env`
- Confirm the API Key has a valid `gfk_` prefix
- Fully quit and restart Codex

## Getting Started

Once verification passes, simply tell Codex what you want to do:

### Create a Dataset from a File

```
Create a dataset from this Excel file
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

### Share a Dataset

```
Share this dataset with xxx@example.com
```

---

## FAQ

### MCP Connection Failed

1. Check whether `GOALFY_UDS_API_KEY` exists in `~/.codex/.env`
2. Confirm the API Key is valid (verify in the console)
3. Fully quit and restart Codex

### uds-cli Command Not Found

Reopen your terminal to refresh the PATH, or invoke the binary by absolute path `"$HOME/.goalfy/bin/uds-cli"` (agent non-interactive shells do not load rc files; the absolute path always works). If login reports `unknown flag: --api-key`, run `uds-cli self-update` first.

### Plugin Installation Failed

Confirm you are running the latest version of Codex. Run `codex plugin marketplace upgrade` to update the cache and try again.

---

## Update

### Plugin Update

**Marketplace installation**: Refresh the marketplace index and re-install:

```bash
codex plugin marketplace upgrade goalfydata
codex plugin remove goalfydata@goalfydata
codex plugin add goalfydata@goalfydata
```

### uds-cli Update

```bash
uds-cli self-update
```

---

## Next Steps

- [Core Concepts](./concepts.md) -- Understand the Build / Run / Share architecture
- [FAQ](../FAQ.md) -- More answers to common questions
