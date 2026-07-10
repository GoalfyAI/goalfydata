# GoalfyData Skill Update Guide — Codex (Agent Edition)

Follow this guide when task creation was rejected with `UDS_SKILL_UPGRADE_REQUIRED`, or whenever you need to bring the goalfydata skill to the latest version. Every step is safe to re-run.

Rules: do not run mutating commands beyond those listed here. Do not ask the user for an API Key — updating never requires one.

## Step 1: Update the plugin

```bash
codex plugin marketplace upgrade goalfydata
codex plugin remove goalfydata@goalfydata
codex plugin add goalfydata@goalfydata
```

Fallback — if the upgrade reports `marketplace 'goalfydata' is not configured as a Git marketplace`, or the reinstalled skill still carries no / an old `[skill-version:...]` marker: the marketplace was originally added from a local directory and keeps reinstalling its stale cache. Rebind it to the official repository, then rerun the remove/add above:

```bash
codex plugin marketplace add GoalfyAI/goalfydata
```

## Step 2: Update uds-cli

```bash
"$HOME/.goalfy/bin/uds-cli" self-update --api-url https://api.goalfydata.ai
```

Both `already on the latest version` and `update succeeded: <old> → <new>` are normal.

## Step 3: Read the new version marker and retry (in this session — do NOT ask the user to restart yet)

The version gate only checks the version string, so you can unblock in the current session. Locate the updated skill file — search for `skills/goalfydata/SKILL.md` rather than reconstructing the path from memory (the install path repeats "goalfydata" at several consecutive levels with a version directory in between, e.g. `.../plugins/cache/goalfydata/goalfydata/<version>/skills/goalfydata/SKILL.md`) — and read `[skill-version:...]` from its description. If the search hits multiple copies (older version directories, marketplace copies), use the one under the highest version directory or the most recently modified one. Retry the failed `uds_task_manager` create with that value, passed verbatim.

## Step 4: Restart so the new skill fully loads

Only after Step 3's retry has succeeded: the retry unblocks task creation, but the skill content loaded in your context is still the old version. Output the template below in the user's conversation language (translate it when the user is not conversing in English; keep it as body text with the H1 heading and bold intact — never inside a code block or blockquote):

# ACTION REQUIRED: Restart to take effect

**Quit Codex completely and reopen it — the updated skill content only takes effect in a new session.**
