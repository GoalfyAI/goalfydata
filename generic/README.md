# GoalfyData — Generic Integration Guide

For AI coding tools not covered by the Claude Code, Codex, or Manus specific guides, or for scenarios requiring manual GoalfyData integration.

If you are using one of the platforms above, refer to the README in the corresponding directory instead.

---

## Integration Steps

### Step 1: Connect the CLI

uds-cli is used for data plane operations (executing SQL, importing data, viewing table schemas).

macOS / Linux:
```bash
curl -fsSL https://cdn.goalfydata.ai/dataset-uds/install.sh | sh
# if "command not found": use "$HOME/.goalfy/bin/uds-cli" instead of uds-cli
uds-cli login --api-url https://api.goalfydata.ai
```

The login command opens the verified GoalfyData connection page. Complete email verification there; the credential is returned directly to uds-cli and saved locally. **Never paste an API Key into an Agent conversation.**

### Step 2: Configure MCP Connection

Prefer your platform's native OAuth connector when available. Otherwise, create `GOALFY_UDS_API_KEY` in the platform's protected secret/environment settings and reference it from the MCP configuration. Never put the plaintext value in a prompt, conversation, or shared configuration:

```json
{
  "mcpServers": {
    "goalfydata-mcp": {
      "type": "streamable-http",
      "url": "https://mcp.goalfydata.ai/mcp",
      "headers": {
        "Authorization": "Bearer ${GOALFY_UDS_API_KEY}"
      }
    }
  }
}
```

MCP configuration formats may vary across tools (field names, transport type syntax, etc.). Adjust according to your tool's documentation. The essentials are:

- **Transport**: streamable-http
- **URL**: `https://mcp.goalfydata.ai/mcp`
- **Authentication**: native OAuth when available; otherwise a protected secret/environment variable sent via the Authorization: Bearer header

MCP configuration and environment-variable syntax vary across tools. If the platform cannot resolve environment variables in MCP headers, enter the value only in that platform's protected connector/secret UI — never in Agent chat.

### Step 3: Load Skill

Download [goalfydata-generic.zip](https://cdn.goalfydata.ai/dataset-uds/guides/generic/goalfydata-generic.zip) and extract it, or clone the repo and use the `generic/` directory.

Import `SKILL.md` and the `references/` directory into your tool. Choose the method based on your platform's capabilities:

| Platform Capability | Action |
|---|---|
| Supports skill upload | Upload the entire `SKILL.md` + `references/` directory |
| Supports system prompts | Paste the contents of `SKILL.md` into the system prompt |
| Supports knowledge base / document attachments | Import all `.md` files as reference documents |

### Step 4: Verification

In your Agent, type:

```
List my datasets
```

If the Agent calls the MCP tool and returns a dataset list, the integration is successful.

---

## Update

### Skill update

The MCP connection points to a remote service and does not require configuration updates. Re-fetch the skill files the same way you originally obtained them:

- **Downloaded the zip**: download [goalfydata-generic.zip](https://cdn.goalfydata.ai/dataset-uds/guides/generic/goalfydata-generic.zip) again and unpack it
- **Cloned the repository**: `cd goalfydata && git pull`

Then re-import the latest `SKILL.md` and `references/` into your tool following Step 4, and **start a new session** (skills are only loaded at session start — without a new session the update does not take effect).

### uds-cli update

```bash
uds-cli self-update
```

Both `already on the latest version` and `update succeeded: <old> → <new>` are normal; if it reports the API URL is not configured, run `uds-cli self-update --api-url https://api.goalfydata.ai` instead.

---

## Rotating the Credential

When the old credential is deleted or needs rotation, complete all steps in order:

1. Run `uds-cli login --api-url https://api.goalfydata.ai` again and complete browser verification
2. Reconnect the platform's native OAuth connector, or update `GOALFY_UDS_API_KEY` only in its protected secret/environment settings
3. Never send the new credential to the Agent or paste it into a conversation
4. Fully restart your agent tool

> Why the restart is required: the configuration saved by login takes effect immediately, but the Agent and MCP connection may keep the previous environment until a full restart. Afterwards, run `uds-cli whoami` only as an exit-code check with stdout and stderr suppressed; never surface its credential output in chat.

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
