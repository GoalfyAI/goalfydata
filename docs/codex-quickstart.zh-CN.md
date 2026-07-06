# Codex 快速开始

3 分钟完成安装，让 Codex 帮你构建实时数据资产。

> 想让 AI 自动安装？把 [AGENTS.zh-CN.md](../codex/AGENTS.zh-CN.md) 发给你的 Agent，由它完成全部步骤。

---

## 第 1 步 — 获取 API Key

到 [GoalfyData](https://goalfydata.ai/settings) 创建 API Key（形如 `gfk_xxx`）。

明文仅在创建时显示一次，请妥善保存。

## 第 2 步 — 安装 uds-cli

uds-cli 用于数据面操作（执行 SQL、导入数据、查看表结构）。

macOS / Linux:
```bash
curl -fsSL https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.sh | sh
# 若提示 command not found：用 "$HOME/.goalfy/bin/uds-cli" 代替 uds-cli
uds-cli login --api-key gfk_你的api_key --api-url https://api.goalfydata.ai
```

## 第 3 步 — 安装插件

Codex CLI：
```bash
codex plugin marketplace add GoalfyAI/goalfydata
codex plugin add goalfydata@goalfydata
```

Codex 桌面版：把 [AGENTS.zh-CN.md](../codex/AGENTS.zh-CN.md) 全文粘贴到对话中（这是面向 Agent 的执行手册），Codex 会自行执行安装命令并完成配置。

## 第 4 步 — 配置 API Key

Codex 桌面版是 Electron 应用，不会继承终端环境变量。需要将 API Key 写入 `~/.codex/.env`：

```bash
# ~/.codex/.env
GOALFY_UDS_API_KEY=gfk_你的api_key
```

配置后重启 Codex 桌面版生效。

Codex CLI（终端）也可使用标准 shell export：

```bash
export GOALFY_UDS_API_KEY="gfk_你的api_key"
```

> 这一步必须做，否则 MCP 连接会因认证失败而报错。

## 第 5 步 — 重启 Codex

完全退出并重新打开 Codex，让插件和 MCP 生效。

## 第 6 步 — 验证

在 Codex 中确认 `goalfydata-mcp` 已连接，工具列表中有 20 个工具（`uds_query`、`uds_dataset_manage` 等）。

如果连接失败：
- 确认 `~/.codex/.env` 中 `GOALFY_UDS_API_KEY` 已配置
- 确认 API Key 是有效的 `gfk_` 前缀
- 完全退出 Codex 重新启动

## 开始使用

验证通过后，直接告诉 Codex 你想做什么：

### 从文件创建数据集

```
帮我把这个 Excel 文件创建成一个数据集
```

### 从 API 拉取数据并定时同步

```
创建一个电商数据集，包含商品、用户、订单三张表
从 DummyJSON API 拉取数据，每天凌晨 2 点自动同步
```

### 查询和分析数据

```
列出我的数据集
```

```
帮我分析订单表，按月统计销售额趋势
```

### 开发数据应用

```
基于这个数据集开发一个仪表盘应用并部署到公网
```

### 分享数据集

```
把这个数据集分享给 xxx@example.com
```

---

## 常见问题

### MCP 连接失败

1. 检查 `~/.codex/.env` 中是否有 `GOALFY_UDS_API_KEY`
2. 确认 API Key 有效（到 https://goalfydata.ai/settings 验证）
3. 完全退出并重启 Codex

### uds-cli 命令找不到

重新打开终端让 PATH 生效；或直接用绝对路径 `"$HOME/.goalfy/bin/uds-cli"` 调用（Agent 的非交互 shell 不加载 rc 文件，绝对路径始终有效）。若 login 提示 `unknown flag: --api-key`，先执行 `uds-cli self-update` 升级。

### 换了 API Key 后操作仍失败

环境里（配置文件或终端 export）残留旧 Key，其优先级高于 login 保存的配置。按「更换 API Key」小节走完全部步骤并完全重启。

### 插件安装失败

确认 Codex 版本为最新。执行 `codex plugin marketplace upgrade` 更新缓存后重试。

---

## 更新

### 插件更新

**marketplace 安装**：刷新市场索引并重新安装：

```bash
codex plugin marketplace upgrade goalfydata
codex plugin remove goalfydata@goalfydata
codex plugin add goalfydata@goalfydata
```

### uds-cli 更新

```bash
uds-cli self-update
```

---

## 更换 API Key

旧 Key 删除或需要轮换时，按顺序完成全部步骤（只做 login 不够：环境变量的优先级高于登录保存的配置，残留的旧值会让 uds-cli 和 MCP 继续使用旧 Key）。

最简单的方式：到官网集成页（ https://goalfydata.ai/integrations/codex ）重新复制接入文本发给你的 Agent，由它自动完成全部步骤。手动操作如下：

1. 到 [GoalfyData](https://goalfydata.ai/settings) 删除旧 Key，创建并复制新 Key
2. 重新登录：`uds-cli login --api-key gfk_新Key --api-url https://api.goalfydata.ai`
3. 把 `~/.codex/.env` 中 `GOALFY_UDS_API_KEY` 的值更新为新 Key
4. 完全退出并重新打开 Codex

---

## 下一步

- [核心概念](./concepts.zh-CN.md) — 理解 Build / Run / Share 架构
- [常见问题](../FAQ.zh-CN.md) — 更多问题解答
