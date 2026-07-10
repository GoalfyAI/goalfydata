# GoalfyData Skill Update Guide — Claude Code (Agent Edition)

Follow this guide when task creation was rejected with `UDS_SKILL_UPGRADE_REQUIRED`, or whenever you need to bring the goalfydata skill to the latest version. Every step is safe to re-run.

Rules: do not run mutating commands beyond those listed here. Do not ask the user for an API Key — updating never requires one.

## Step 1: Update the plugin

```bash
# marketplace install (default)
claude plugin update goalfydata@goalfydata

# local git clone install
cd goalfydata && git pull && claude plugin marketplace update goalfydata
```

## Step 2: Update uds-cli

```bash
"$HOME/.goalfy/bin/uds-cli" self-update --api-url https://api.goalfydata.ai
```

Both `already on the latest version` and `update succeeded: <old> → <new>` are normal.

## Step 3: Read the new version marker and retry

The version gate only checks the version string, so you can unblock in the current session. Locate the updated skill file — search for `skills/goalfydata/SKILL.md` rather than reconstructing the path from memory (the install path repeats "goalfydata" at several consecutive levels with a version directory in between, e.g. `.../plugins/cache/goalfydata/goalfydata/<version>/skills/goalfydata/SKILL.md`) — and read `[skill-version:...]` from its description. If the search hits multiple copies (older version directories, marketplace copies), use the one under the highest version directory or the most recently modified one. Retry the failed `uds_task_manager` create with that value, passed verbatim.

## Step 4: Restart so the new skill fully loads

The retry above unblocks task creation, but the skill content loaded in your context is still the old version. Output the template below in the user's conversation language (translate it when the user is not conversing in English; keep it as body text with the H1 heading and bold intact — never inside a code block or blockquote):

# ACTION REQUIRED: Restart to take effect

**Run `/reload-plugins` in the session, or quit Claude Code completely and reopen it — the updated skill content only takes effect afterwards.**
