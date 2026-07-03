# Core Concepts

## What is GoalfyData?

GoalfyData is a runtime platform for AI Agents to build data assets. The Agent creates the assets; GoalfyData keeps them running.

## Three-Layer Architecture: Build -> Run -> Share

### 1. Build -- Enable Any Agent to Build Data Assets

GoalfyData does not replace your AI Agent -- it enhances it.

Through Skill / MCP / CLI, GoalfyData integrates into your existing Agent workflow:

- Claude Code
- Codex
- Manus
- ChatGPT / Custom GPTs

Your Agent can naturally produce:

- **Datasets** -- Structured data generated from APIs, files, or databases
- **Update Scripts** -- Python / TypeScript scripts that automatically refresh data
- **Templates** -- Reusable data structures and configurations
- **Data Apps** -- Visual data applications built by the Agent

**Key Insight**: Users don't need to learn a complex platform first. They build assets directly within the Agent they already use.

### 2. Run -- Keep Assets Running and Updated

This is the core differentiator between GoalfyData and every other tool.

Agent outputs are typically ephemeral:

- Scripts that only run locally
- CSVs that expire within a week
- Dashboards that stop working when you close the tab

GoalfyData transforms them into continuously running services:

- **Scheduled Sync** -- Cron-based automatic data refresh
- **Sandbox Execution** -- Update scripts run in isolated environments
- **Version Control** -- Track changes and roll back when needed
- **Atomic Updates** -- full_replace mode ensures no empty-table intermediate states

Agents can build anything, and GoalfyData keeps it running.

### 3. Share -- Secure, Controlled, Cross-Agent Reuse

Data assets only generate real value when they can be shared and reused.

GoalfyData transforms scattered files into manageable, shareable assets:

- **Share with Colleagues** -- Role-based access control
- **Share with Clients** -- Read-only or preview permissions
- **Team Sharing** -- Organization-level data assets
- **Share with Other Agents** -- Agent-to-Agent data flows

Permission levels: View / Preview / Query / Update / Manage

**Problem Solved**: No more emailing CSVs, no more repeatedly explaining data definitions, and no more rebuilding the same dataset in every new Agent conversation.

## What GoalfyData Is Not

Understanding boundaries is just as important as understanding value.

| GoalfyData Is Not | It Is |
|---|---|
| An AI Agent | A runtime platform for data assets built by Agents |
| A BI Tool (Tableau/Looker) | A platform where Agents build data apps, not humans manually |
| A Lightweight dbt | A hosting layer for Agent-generated data pipelines |
| An MCP Tool/Server | A persistence layer for data after MCP connects it |
| A General App Host (Vercel) | A hosting platform designed specifically for Agent-built data assets |

GoalfyData is the infrastructure layer that every AI Agent needs, but no single Agent provides.

## Why It Matters Now

Three major trends are converging:

1. **Agents Are in Production** -- 57.3% of organizations are already running Agents (LangChain Survey 2026)
2. **MCP Is Becoming a Standard** -- 28% of Fortune 500 companies have adopted MCP as infrastructure
3. **Output Persistence Is the Gap** -- Everyone talks about agent memory, but no one solves the problem of making agent outputs persist

GoalfyData fills exactly this gap.

## Architecture Overview

```
AI Agents (Claude / Codex / Manus)
    |
    |  Build: Skill / MCP / CLI
    v
+----------------------------------+
|           GoalfyData             |
|                                  |
|  +-----------+  +--------------+ |
|  |  Datasets |  |  Data Apps   | |
|  +-----+-----+  +------+------+ |
|        |               |        |
|  +-----v-----+  +------v------+ |
|  | Scheduled  |  |   Version   | |
|  |    Sync    |  |   Control   | |
|  +-----+-----+  +------+------+ |
|        |               |        |
|  +-----v---------------v------+ |
|  |      Sandbox Execution      | |
|  +-------------+---------------+ |
|                |                 |
|  +-------------v---------------+ |
|  |   Sharing & Access Control  | |
|  +-----------------------------+ |
+----------------------------------+
    |
    v
Teams / Clients / Other Agents
```
