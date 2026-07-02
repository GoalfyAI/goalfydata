# GoalfyData — Generic Integration Guide

For AI coding tools not covered by the Claude Code, Cursor, Codex, or Manus specific guides, or for scenarios requiring manual GoalfyData integration.

If you are using one of the four platforms above, refer to the README in the corresponding directory instead.

---

## Integration Steps

### Step 1: Obtain API Token

Go to the [GoalfyData Console](https://goalfydata.ai/settings) to create an API Key (in the format `gfk_xxx`).

The plaintext key is only shown once at creation time -- save it securely.

### Step 2: Install uds-cli

uds-cli is used for data plane operations (executing SQL, importing data, viewing table schemas).

macOS / Linux:
```bash
curl -fsSL https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.sh | sh
source ~/.zshrc  # or source ~/.bashrc
uds-cli login --token gfk_your_token --api-url https://api.goalfydata.ai
```

### Step 3: Configure MCP Connection

Merge the following configuration into your tool's MCP configuration file, replacing `gfk_YOUR_TOKEN_HERE` with your actual token:

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

MCP configuration formats may vary across tools (field names, transport type syntax, etc.). Adjust according to your tool's documentation. The essentials are:

- **Transport**: streamable-http
- **URL**: `https://mcp.goalfydata.ai/mcp`
- **Authentication**: Bearer Token in the Authorization header

### Step 4: Load Skill

Download [goalfydata-generic.zip](https://github.com/GoalfyAI/goalfydata/raw/main/generic/goalfydata-generic.zip) and extract it, or clone the repo and use the `generic/` directory.

Import `SKILL.md` and the `references/` directory into your tool. Choose the method based on your platform's capabilities:

| Platform Capability | Action |
|---|---|
| Supports skill upload | Upload the entire `SKILL.md` + `references/` directory |
| Supports system prompts | Paste the contents of `SKILL.md` into the system prompt |
| Supports knowledge base / document attachments | Import all `.md` files as reference documents |

### Step 5: Verification

In your Agent, type:

```
List my datasets
```

If the Agent calls the MCP tool and returns a dataset list, the integration is successful.

---

## Update

### Skill update

The MCP connection points to a remote service and does not require configuration updates. Skill files need to be pulled again:

```bash
cd goalfydata && git pull
```

Then re-import the latest `SKILL.md` and `references/` into your tool following Step 4.

### uds-cli update

```bash
uds-cli self-update
```

---

## Directory Structure

```
generic/
├── .mcp.json                              # MCP server configuration template
├── SKILL.md                               # Core skill file (tool descriptions + workflow + constraints)
└── references/                            # Reference guides
    ├── dataset-building-guide.md          # Dataset building guide
    ├── data-quality-guide.md              # Data quality guide
    ├── scheduled-sync-guide.md            # Scheduled sync guide
    └── app-deploy-guide.md               # Data app deploy guide
```

## Relationship with Platform-Specific Versions

`generic/` is the upstream source for all platform versions. Each platform directory (`claude-code/`, `cursor/`, etc.) adapts from this source for its own plugin format. When modifying SKILL.md or references, update all platform directories together.
