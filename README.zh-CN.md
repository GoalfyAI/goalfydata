<p align="right">
  <a href="./README.md">English</a> |
  <a href="./README.zh-CN.md">简体中文</a>
</p>

<br>

<p align="center">
  <a href="https://goalfydata.ai/">
    <img src="./assets/Goalfydata.svg" alt="GoalfyData Logo" width="320">
  </a>
</p>

<p align="center">
  <strong>Agent 生成的数据，不应该在一次任务结束后就消失。</strong>
</p>

<p align="center">
  GoalfyData 会把 Agent 的输出结果，变成结构化、可治理、可持续复用的数据资产<br>
供 AI Agent 和团队长期使用。
</p>

<p align="center">
  <a href="https://goalfydata.ai"><img alt="Website" src="https://img.shields.io/badge/website-goalfydata.ai-6366F1"></a>
  <img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-blue">
  <img alt="Status" src="https://img.shields.io/badge/status-preview-orange">
  <img alt="Agent Callable" src="https://img.shields.io/badge/agent--callable-yes-green">
</p>

<p align="center">
  <a href="https://goalfydata.ai"><strong>官网</strong></a>
  ·
  <a href="#overview">概览</a>
  ·
  <a href="#problem">解决问题</a>
  ·
  <a href="#quickstart">快速开始</a>
</p>

<br>

---

<a id="overview"></a>

## 🔗 一句话理解

AI Agent 可以快速生成数据集、脚本、报告和 dashboard。

但 Agent 生成的数据，常常会被困在一次对话、一个本地文件、或某个 Agent 工作区里。

**GoalfyData 会把这些输出结果变成持久的数据资产，让它们可以在不同会话、不同 Agent和团队成员之间持续复用。**

> [!TIP]
> Agent 负责生成第一版，GoalfyData 负责让它持续运行、治理、共享和复用。

---

<a id="problem"></a>

## ❓ GoalfyData 解决什么问题？

AI Agent 已经很擅长"生成第一版"，但很多产物仍然停留在一次性结果：

| 常见产物            | 现实问题                       |
| --------------- | -------------------------- |
| **脚本**          | 只能在本地电脑运行，换人、换环境后很难继续维护    |
| **CSV / Excel** | 需要反复上传给不同 AI，字段含义和业务规则容易丢失 |
| **数据集**         | 缺少统一的更新机制、版本管理和权限控制        |
| **Dashboard**   | 数据源变化后很快过期，需要人工刷新或重新生成     |
| **客户报告**        | 交付的是静态文件，不是持续更新的数据资产       |
| **Agent 工作流**   | 不同 Agent 很难复用同一份被治理过的数据上下文 |

---

## 🚫 GoalfyData 不是什么？

GoalfyData 不是一个泛数据平台，也不是单纯的 BI 工具。
它更像是 **AI Agent 生成数据资产之后的运行与治理层**。

| 不是                                    | GoalfyData 更关注              |
| ------------------------------------- | --------------------------- |
| 不是普通网盘                                | 让数据资产可以被 Agent 调用、理解和复用     |
| 不是传统数据库                               | 补充 Agent 需要的字段含义、业务规则和使用指南  |
| 不是单纯 dashboard 工具                     | 让 dashboard 背后的数据可以持续更新和被治理 |
| 不是一次性文件上传工具                           | 让数据集进入创建、更新、版本、分享和停用的生命周期   |
| 不是替代 Claude / Codex / Manus / ChatGPT | 为不同 Agent 提供统一、可调用的数据层      |

> [!IMPORTANT]
> GoalfyData 的重点不是"存文件"，而是让 Agent 生成的数据资产可以被持续运行、治理和复用。

---

## ⚙️ GoalfyData 如何工作？

GoalfyData 围绕 **Build → Run → Share** 组织 Agent 数据资产的生命周期。

| 阶段           | 说明                                                   | 结果         |
| ------------ | ---------------------------------------------------- | ---------- |
| **Build 构建** | Agent 从文件、API、数据库或表格中创建数据集、脚本、数据面板，并补充字段定义、表间关系和使用规则 | 生成可理解的数据资产 |
| **Run 运行**   | GoalfyData 负责定时刷新、任务执行、沙箱运行、版本管理、日志和失败通知             | 让数据资产持续运行  |
| **Share 分享** | 团队可以将数据资产安全分享给成员、客户、协作者或其他 Agent，并控制访问权限             | 让数据资产被安全复用 |

---

<a id="preview"></a>

## 🖼️ 产品界面预览
> [!NOTE]
> Demo 视频即将补充。  
> 视频将展示 GoalfyData 如何把 Agent 生成的数据集、脚本和 dashboard，变成可持续更新、可治理、可共享的数据资产。

<!--
<p align="center">
  <a href="https://your-demo-video-link.com">
    <img src="./assets/video-cover.png" alt="Watch GoalfyData Demo" width="100%">
  </a>
</p>
-->
## 🔐 分享与授权逻辑

GoalfyData 帮助团队安全地把数据资产分享给团队成员、客户、协作者和授权 Agent。

你不需要复制文件、发送表格、或手动限制字段，而是可以直接描述谁应该访问什么：

> 除了财务明细表，其余表都可以分享给 xxx@company.com。

GoalfyData 会把这个意图转化为数据边界和权限规则，确保正确的数据交给正确的人和 Agent。

典型分享方式包括：

* 分享数据集给团队成员，用于协作分析
* 分享持续更新的数据结果给客户
* 授权另一个 Agent 把数据集作为业务上下文
* 按角色、表、字段或规则控制访问范围
---

## 🧩 核心能力

| 能力           | 说明                                                                          |
| ------------ | --------------------------------------------------------------------------- |
| **Agent 接入** | 通过 MCP、CLI、API 或 Actions 接入 Claude Code、Codex、Cursor、Manus、ChatGPT 等 Agent |
| **数据集托管**    | 托管 Agent 生成或整理的数据集，让它们不再只是本地文件或一次性表格                                       |
| **治理上下文**    | 管理字段含义、计算口径、表间关系、业务规则和使用约束                                                 |
| **持续更新**     | 支持定时刷新、数据同步、脚本执行、版本管理和失败通知                                                 |
| **安全共享**     | 支持团队、客户和其他 Agent 的权限化访问，避免重复传文件                                            |
| **结果输出**     | 支持将数据集用于报告、分析、dashboard 和自动化工作流                                            |
> GoalfyData 的核心不是替代 Agent，而是为不同 Agent 提供一层可复用、可治理、可持续更新的数据资产层。

---

<a id="quickstart"></a>

## 🚀 快速开始

| 平台 | 指南 |
|------|------|
| **Claude Code** | [Claude Code 快速开始](./docs/claude-code-quickstart.zh-CN.md) |
| **Cursor** | [Cursor 快速开始](./docs/cursor-quickstart.zh-CN.md) |
| **Codex** | [Codex 快速开始](./docs/codex-quickstart.zh-CN.md) |
| **Manus** | [Manus 快速开始](./docs/manus-quickstart.zh-CN.md) |
| **其他平台** | [通用接入指南](./generic/README.zh-CN.md) |

---

## 🤖 支持的 AI Agent

| Agent / 平台                | 接入方式           | 状态        |
| ------------------------- | -------------- | --------- |
| **Claude Code**           | MCP / Plugin   | Available |
| **Cursor**                | MCP / Plugin   | Available |
| **Codex**                 | CLI / Plugin   | Available |
| **Manus**                 | API            | Available |
| **ChatGPT / Custom GPTs** | Actions        | Planned   |
| **通用 Agent**              | REST API / CLI | Available |

---


## 📖 文档

| 文档                                                    | 说明                                         |
| ----------------------------------------------------- | ------------------------------------------ |
| [Claude Code 快速开始](./docs/claude-code-quickstart.zh-CN.md) | 安装并使用 Claude Code 插件                       |
| [Cursor 快速开始](./docs/cursor-quickstart.zh-CN.md)           | 安装并使用 Cursor 插件                            |
| [Codex 快速开始](./docs/codex-quickstart.zh-CN.md)             | 安装并使用 Codex 插件                             |
| [Manus 快速开始](./docs/manus-quickstart.zh-CN.md)             | 安装并使用 Manus                                |
| [核心概念](./docs/concepts.zh-CN.md)                           | 理解 Dataset、Governance Rules、Skills 和 Relationships |
| [常见问题](./FAQ.zh-CN.md)                                     | GoalfyData 常见问题                            |

---

<a id="community"></a>

## 🤝 社区与反馈

欢迎反馈 GoalfyData 的使用问题、集成需求和真实业务场景。

| 入口 | 适合提交什么 |
|---|---|
| [报告 Bug](https://github.com/GoalfyAI/goalfydata/issues/new?template=bug_report.md) | 已确认的 bug、安装失败、Agent 集成异常、数据更新失败、权限问题和回归问题。 |
| [提问](https://github.com/GoalfyAI/goalfydata/discussions/categories/q-a) | 安装、配置、使用和排查问题。 |
| [提出想法](https://github.com/GoalfyAI/goalfydata/discussions/categories/ideas) | 新 Agent 集成、数据集能力、治理规则、分享权限、dashboard 想法和 workflow 改进。 |
| [分享用例](https://github.com/GoalfyAI/goalfydata/discussions/categories/show-and-tell) | 业务数据场景、Agent workflow、团队协作场景和 demo。 |

⭐ 如果 GoalfyData 帮助你把 AI Agent 的输出变成了可持续更新的数据资产，欢迎支持我们。


---

## ⚖️ 开源协议

本仓库中的客户端工具、示例和文档遵循 [Apache-2.0 License](./LICENSE)。

© GoalfyData Team

GoalfyData 托管服务本身适用单独的服务条款。
