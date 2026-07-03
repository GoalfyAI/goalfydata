# GoalfyData — Manus Integration

> **Note: Manus does NOT support pasting this document to the agent for automatic installation. Adding the connector and uploading the skill must be done manually by you in the Manus web interface — follow the steps below one by one.**

Manus is a cloud-based agent with two parts to configure separately: **Tools (MCP)** are added as a connector in the plugin page; **Skills** are uploaded as skill files.

## Step 1: Obtain API Key

Go to the [GoalfyData Console](https://goalfydata.ai/settings) to create an API Key (in the format `gfk_xxx`). The plaintext key is only shown once at creation time -- save it securely.

## Step 2: Add MCP Connector (Tools)

Go to **Plugins** in the left sidebar -> click **Create** in the top right -> in the Connector area, choose one of the two methods:

### Method A: Import MCP via JSON (recommended)

Click **Import MCP via JSON**, paste the following JSON, replace `gfk_YOUR_API_KEY_HERE` with your API Key, and save.

```json
{
  "mcpServers": {
    "goalfydata-mcp": {
      "url": "https://mcp.goalfydata.ai/mcp",
      "transport": "streamable_http",
      "headers": {
        "Authorization": "Bearer gfk_YOUR_API_KEY_HERE"
      }
    }
  }
}
```

### Method B: Custom MCP (fill in form fields)

Click **Custom MCP** and fill in each field as follows:

| Field | Value |
|---|---|
| **Server Name** | `GoalfyData` |
| **Transport Type** | `HTTP` (keep default) |
| **Icon (optional)** | Leave empty, or paste a logo URL |
| **Notes (optional)** | Leave empty or add a usage description |
| **Server URL** | `https://mcp.goalfydata.ai/mcp` |
| **Custom Headers** | Click "+ Add custom header", add 1 entry |

Custom header (authentication, required):
- Key: `Authorization`
- Value: `Bearer gfk_your_actual_api_key`

Save when done.

## Step 3: Upload Skill

Go to **Plugins** in the left sidebar -> click **Create** in the top right -> in the Skill area -> **Upload Skill**.

Manus requires uploading a `.zip` or `.skill` file with `SKILL.md` in the root directory.

**Download pre-built ZIP**: Download [goalfydata-skill.zip](https://github.com/GoalfyAI/goalfydata/raw/main/manus/goalfydata-skill.zip) directly and skip to the upload step below.

**Or package manually**:

```bash
cd manus/skill
zip -r goalfydata-skill.zip SKILL.md references/
```

Drag and drop the generated `goalfydata-skill.zip` into the upload area.

Alternatively, you can choose **Import Skill from GitHub**, enter the repository URL `GoalfyAI/goalfydata`, and specify the `manus/skill/` path to import.

Manus automatically registers the skill upon import; you can also invoke it explicitly with `/goalfydata` in a conversation.

## Verification

Connector status shows connected + `goalfydata` appears in Skills -> type "list my datasets" in a conversation to verify.

## Update

### Skill update

The MCP connector points to a remote service and does not need updating. Skill files need to be updated manually:

1. Delete the old `goalfydata` Skill from the Skills management page
2. Re-package and upload the latest `skill/` directory (`zip -r goalfydata-skill.zip SKILL.md references/`)
3. Close the current conversation and open a new one (Skills are only loaded at session start)


## Troubleshooting

1. **Server URL must be publicly accessible** -- Manus runs on its own cloud and cannot reach private networks. This is the most common cause of failure.
2. **API Key** is incorrect or missing the `Bearer ` prefix.
3. Try `HTTP` for transport type first; if that doesn't work, check if Manus offers a `Streamable HTTP` option.
