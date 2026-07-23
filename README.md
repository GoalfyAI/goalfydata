<br>

<p align="center">
  <a href="https://goalfydata.ai/">
    <img src="./assets/Goalfydata.svg" alt="GoalfyData Logo" width="320">
  </a>
</p>

<p align="center">
  <strong>A shared place for AI agents to build, update, analyze, and reuse business data.</strong>
</p>

<p align="center">
  Turn spreadsheets, APIs, databases, and agent outputs into reusable datasets and data apps<br>
  that preserve business context and stay up to date.
</p>

<p align="center">
  <a href="https://goalfydata.ai"><img alt="Website" src="https://img.shields.io/badge/website-goalfydata.ai-6366F1"></a>
  <img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-blue">
  <img alt="Status" src="https://img.shields.io/badge/status-preview-orange">
  <img alt="Agent Callable" src="https://img.shields.io/badge/agent--callable-yes-green">
</p>

<p align="center">
  <a href="https://goalfydata.ai"><strong>Website</strong></a>
  ·
  <a href="https://goalfydata.ai/integrations"><strong>Get Started</strong></a>
  ·
  <a href="#documentation"><strong>Documentation</strong></a>
</p>

---

## Understand GoalfyData in 30 Seconds

Codex, Claude Code, Manus, and other connected agents can create datasets, write update scripts, analyze results, and build data apps. GoalfyData keeps the resulting data together with its field definitions, metric definitions, table relationships, permissions, and governance rules.

The result is a durable data asset that can be reused across conversations, agents, devices, and teams. Import data, run SQL analysis, schedule updates, share with controlled access, and deploy data apps from the same dataset. When the dataset updates, connected apps continue to read the latest data.

## Quick Start

The fastest path is to open the integration page for your platform, copy its setup instructions, and give them to your agent. Create your API Key in [GoalfyData Settings](https://goalfydata.ai/settings); keys use the `gfk_` prefix and are shown only once.

| Platform | Fastest setup | Detailed guide | Status |
|---|---|---|---|
| **Codex** | [Open the Codex integration](https://goalfydata.ai/integrations/codex) and send the setup text to Codex | [Codex Quick Start](./docs/codex-quickstart.md) | Available |
| **Claude Code** | [Open the Claude Code integration](https://goalfydata.ai/integrations/claude-code) and send the setup text to Claude Code | [Claude Code Quick Start](./docs/claude-code-quickstart.md) | Available |
| **Manus** | [Open the Manus integration](https://goalfydata.ai/integrations/manus), then add the MCP connector and upload the Skill in Manus | [Manus Quick Start](./docs/manus-quickstart.md) | Available |
| **Other Agents / Generic MCP** | Connect the remote MCP and load the generic Skill | [Generic Integration Guide](./generic/README.md) | Available for compatible MCP/CLI agents |

> Manus setup currently requires manual steps in its web interface; it cannot be completed by pasting an install runbook into a Manus conversation.

### Minimal manual CLI setup

For macOS or Linux developers who prefer manual setup:

```bash
curl -fsSL https://cdn.goalfydata.ai/dataset-uds/install.sh | sh
uds-cli login --api-key gfk_your_api_key --api-url https://api.goalfydata.ai
```

Then follow the platform guide above to install the Skill/plugin and connect MCP. The detailed guides cover Windows, updates, key rotation, and troubleshooting. A successful connection exposes 20 GoalfyData MCP tools, including `uds_query` and `uds_dataset_manage`.

## Try These First

After connecting, attach the relevant file or provide the source details, then copy one of these requests to your agent:

```text
Turn this Excel file into a reusable dataset. Preserve the field meanings, metric definitions, and table relationships.
```

```text
Analyze the orders data and report monthly sales, order count, and refund rate.
```

```text
Update this dataset from the API every day. Notify me if a managed refresh fails.
```

```text
Build a sales dashboard from this dataset and deploy it as a shareable data app.
```

```text
Share this dataset with xxx@example.com and give them view-only access to the approved data.
```

## From Request to Reusable Result

**You ask:**

> Merge Shopify orders and ad reports, update them daily, and analyze GMV, refund rate, and ROAS.

**Your agent and GoalfyData:**

1. Create or reuse a dataset.
2. Import, clean, and relate the source data.
3. Save field meanings and metric definitions.
4. Configure a Managed Refresh for daily updates.
5. Create an analysis or dashboard backed by the dataset.
6. Share the result using controlled access.

**You get:** one continuously updated data asset that preserves its business definitions and remains reusable across conversations and connected agents.

## Core Capabilities

| Capability | What it enables |
|---|---|
| **Data import and hosting** | Turn spreadsheets, CSV files, APIs, databases, and agent outputs into hosted datasets |
| **Business context** | Preserve field meanings, metric definitions, table relationships, processing rules, and usage guidance |
| **SQL and agent analysis** | Query and analyze governed datasets through the CLI and MCP tools |
| **Managed Refresh** | Run scheduled update scripts in an isolated environment, with logs and failure status |
| **Controlled sharing** | Share datasets and results with teammates, clients, and authorized agents using permissions |
| **Data App Deployment** | Deploy dashboards and lightweight apps that continue to read the latest dataset data |

## How It Works

GoalfyData organizes the lifecycle around **Build → Run → Share**.

| Stage | What happens | Result |
|---|---|---|
| **Build** | Agents create datasets, update scripts, analyses, and apps from files, APIs, databases, or spreadsheets | An understandable data asset with business context |
| **Run** | GoalfyData hosts datasets and runs scheduled updates with version and status information | Data stays available and up to date |
| **Share** | Teams grant controlled access to datasets and apps | People and agents reuse the same governed result |

## Supported Platforms

| Agent / platform | Integration | Status |
|---|---|---|
| **Codex** | Plugin, MCP, and CLI | Available |
| **Claude Code** | Plugin, MCP, and CLI | Available |
| **Manus** | Remote MCP connector and uploaded Skill | Available |
| **Other compatible agents** | Remote MCP, generic Skill, and CLI | Available; setup varies by platform |

## What This Repository Contains

This repository provides the client-side materials needed to connect agents to GoalfyData:

- Codex and Claude Code plugins, Skills, MCP configuration, and agent-executable install runbooks
- Manus and generic-agent Skill packages
- Platform quick-start guides, examples, update instructions, and troubleshooting documentation
- Community, contribution, security, and license files

GoalfyData datasets, Managed Refresh, permission sharing, and Data App Deployment are provided by the hosted GoalfyData service. Cloning this repository installs none of those server-side services and is **not** a self-hosted GoalfyData deployment.

## What GoalfyData Is Not

GoalfyData does not replace your AI agent, operational database, spreadsheet, or BI tool. It provides the reusable data asset layer that lets connected agents preserve business context, keep data updated, and share results safely.

<a id="documentation"></a>

## Documentation

| Resource | Use it for |
|---|---|
| [Codex Quick Start](./docs/codex-quickstart.md) | Codex installation, verification, updates, and troubleshooting |
| [Claude Code Quick Start](./docs/claude-code-quickstart.md) | Claude Code installation, verification, updates, and troubleshooting |
| [Manus Quick Start](./docs/manus-quickstart.md) | Manus MCP and Skill setup |
| [Generic Integration Guide](./generic/README.md) | Other MCP/CLI-compatible agents |
| [Core Concepts](./docs/concepts.md) | Datasets, governance rules, Skills, and relationships |
| [FAQ](./FAQ.md) · [Website FAQ](https://goalfydata.ai/faq) | Product and plan questions |

## Community and Security

| Entry | What to submit |
|---|---|
| [Report a Bug](https://github.com/GoalfyAI/goalfydata/issues/new?template=bug_report.md) | Confirmed bugs, installation failures, integration issues, or regressions |
| [Ask a Question](https://github.com/GoalfyAI/goalfydata/discussions/categories/q-a) | Setup, usage, and troubleshooting questions |
| [Suggest an Idea](https://github.com/GoalfyAI/goalfydata/discussions/categories/ideas) | New integrations and product ideas |
| [Share a Use Case](https://github.com/GoalfyAI/goalfydata/discussions/categories/show-and-tell) | Agent workflows, business scenarios, and demos |
| [Security Policy](./SECURITY.md) | How to report a vulnerability privately |

## License and Service Terms

The client tools, plugins, Skills, examples, and documentation in this repository are licensed under the [Apache-2.0 License](./LICENSE).

GoalfyData's hosted datasets, Managed Refresh, sharing, and Data App Deployment are provided under the separate [GoalfyData Terms of Service](https://goalfydata.ai/terms).

© GoalfyData Team
