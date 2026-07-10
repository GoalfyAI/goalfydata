# GoalfyData Skill Update Guide — Manus (Agent Edition)

Follow this guide when task creation was rejected with `UDS_SKILL_UPGRADE_REQUIRED`, or whenever you need to bring the goalfydata skill to the latest version.

The MCP connector points to a remote service and does not need updating, and Manus has no local uds-cli (the cloud sandbox is provisioned by the platform) — only the Skill files need replacing. Skills are managed by the user on the Skills page, and on Manus there is no way to unblock within the current conversation (the updated skill file is not readable from here); the only path is a new conversation with the updated skill. So guide the user through the replacement:

## Step 1: Replace the skill

Output the template below in the user's conversation language (translate it when the user is not conversing in English; keep it as body text with the H1 heading and bold intact — never inside a code block or blockquote):

# ACTION REQUIRED: Update the goalfydata skill

**1. Download the latest skill package: https://github.com/GoalfyAI/goalfydata/raw/main/manus/goalfydata-skill.zip**

**2. On the Manus Skills management page, delete the old `goalfydata` skill, then upload the new zip.**

**3. Close the current conversation and open a new one — skills are only loaded at session start.**

## Step 2: Resume in the new conversation

In the new conversation, the updated skill carries the new `[skill-version:...]` in its description, and creating a task per the skill's instructions passes the version gate automatically — ask the user to simply repeat their original request there.

Never fabricate a version string in the current conversation — on Manus the only valid source is the newly installed skill, which is only readable after the restart.
