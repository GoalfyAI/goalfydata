# Manus Quick Start

> **Note: Manus does NOT support pasting this document to the agent for automatic installation. Adding the connector and uploading the skill must be done manually by you in the Manus web interface — follow the steps below one by one.**

Get set up in 3 minutes and let Manus help you build real-time data assets.

---

## Step 1 -- Get an API Key

Go to the [GoalfyData](https://goalfydata.ai/settings) to create an API Key (in the format `gfk_xxx`).

The plaintext key is only shown once at creation time. Save it in a secure location.

## Step 2 -- Add MCP Connector (Tool)

Go to **Plugins** in the left sidebar -> click **Create** in the top right -> choose one of the two methods in the connector section:

### Option 1: Import MCP via JSON (Recommended)

Copy the following JSON, replace `gfk_YOUR_API_KEY_HERE` with your actual API Key, paste it in, and save:

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

### Option 2: Custom MCP

Fill in each field as follows:

| Field | Value |
|-------|-------|
| **Server Name** | `GoalfyData` |
| **Transport Type** | `HTTP` |
| **Server URL** | `https://mcp.goalfydata.ai/mcp` |
| **Custom Headers** | Name: `Authorization`, Value: `Bearer gfk_your_actual_api_key` |

## Step 3 -- Upload Skill

Go to **Plugins** in the left sidebar -> click **Create** in the top right -> Skills section -> **Upload Skill**.

Manus requires uploading a `.zip` or `.skill` file with `SKILL.md` at the root level.

**Download pre-built ZIP**: Download [goalfydata-skill.zip](https://github.com/GoalfyAI/goalfydata/raw/main/manus/goalfydata-skill.zip) directly and skip to the upload step below.

**Or clone and package manually**:

```bash
git clone https://github.com/GoalfyAI/goalfydata.git
cd goalfydata/manus/skill
zip -r goalfydata-skill.zip SKILL.md references/
```

Drag and drop the generated `goalfydata-skill.zip` into the upload area.

## Step 4 -- Verify

Once the connector status shows connected and `goalfydata` appears in Skills, say "List my datasets" in the chat to test.

If the connection fails:
- Confirm the server URL is correct
- Confirm the API Key is entered correctly, including the `Bearer ` prefix
- Manus runs in the cloud -- the URL must be publicly accessible

## Getting Started

Once verification passes, simply say in a Manus conversation:

### Create a Dataset from a File

```
Create a dataset from this CSV file
```

### Pull Data from an API

```
Create an e-commerce dataset, pull product and user data from the DummyJSON API
```

### Query Data

```
List my datasets
```

```
Query the first 10 rows from the orders table
```

### Share a Dataset

```
Share this dataset with xxx@example.com
```

---

## FAQ

### Connector Shows Error

1. The server URL must be publicly accessible (Manus runs in the cloud)
2. Check whether the API Key is incorrect or missing the `Bearer ` prefix
3. For transport type, start with `HTTP`. If that doesn't work, check whether Manus offers a `Streamable HTTP` option

### Skill Not Recognized

Confirm you uploaded a `.zip` file packaged from the `manus/skill/` directory, with `SKILL.md` at the root of the zip. Do not upload files from other platforms.

---

## Update

### Skill Update

MCP connector points to the remote service, no update needed. Skill files need to be manually updated:

1. Delete the old `goalfydata` Skill in the Skills management page
2. Download the latest [goalfydata-skill.zip](https://github.com/GoalfyAI/goalfydata/raw/main/manus/goalfydata-skill.zip) and re-upload
3. Close the current conversation and reopen (Skills are only loaded at session start)


---

## Rotating the API Key

When the old key is deleted or needs rotation:

1. Delete the old key and create/copy a new one in the [GoalfyData](https://goalfydata.ai/settings)
2. In the Manus connector settings, update the `Authorization` value to `Bearer gfk_your_new_key` and save
3. Close the current conversation and open a new one (connector changes take effect in new sessions)

---

## Next Steps

- [Core Concepts](./concepts.md) -- Understand the Build / Run / Share architecture
- [FAQ](../FAQ.md) -- More answers to common questions
