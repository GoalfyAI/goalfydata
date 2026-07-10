# GoalfyData Skill Update Guide — Generic Platforms (Agent Edition)

Follow this guide when task creation was rejected with `UDS_SKILL_UPGRADE_REQUIRED`, or whenever you need to bring the goalfydata skill to the latest version. Every step is safe to re-run.

The MCP connection points to a remote service and does not require configuration updates — only the skill files and uds-cli do. Do not ask the user for an API Key — updating never requires one.

## Step 1: Re-fetch the skill files

Re-fetch the same way the skill was originally obtained:

- **Downloaded the zip**: download https://github.com/GoalfyAI/goalfydata/raw/main/generic/goalfydata-generic.zip again and unpack it
- **Cloned the repository**: `cd goalfydata && git pull`

## Step 2: Update uds-cli

```bash
"$HOME/.goalfy/bin/uds-cli" self-update --api-url https://api.goalfydata.ai
```

Both `already on the latest version` and `update succeeded: <old> → <new>` are normal.

## Step 3: Read the new version marker and retry

The version gate only checks the version string, so you can unblock in the current session: read `[skill-version:...]` from the description of the `SKILL.md` you just fetched in Step 1 (you know where it landed — no need to search). Retry the failed `uds_task_manager` create with that value, passed verbatim.

## Step 4: Re-import and restart so the new skill fully loads

The retry above unblocks task creation, but the skill content loaded in your context is still the old version. Output the template below in the user's conversation language (translate it when the user is not conversing in English; keep it as body text with the H1 heading and bold intact — never inside a code block or blockquote):

# ACTION REQUIRED: Re-import the skill and start a new session

**1. Re-import the updated `SKILL.md` and `references/` into your tool the same way as the initial setup.**

**2. Start a new session — skills are only loaded at session start; without a new session the updated content does not take effect.**
