# Codex 快速开始

3 分钟完成安装，让 Codex 帮你构建实时数据资产。

---

## 第 1 步 — 获取 API Token

到 [GoalfyData 控制台](https://goalfydata.ai/settings) 创建 API Key（形如 `gfk_xxx`）。

明文仅在创建时显示一次，请妥善保存。

## 第 2 步 — 安装 uds-cli

uds-cli 用于数据面操作（执行 SQL、导入数据、查看表结构）。

macOS / Linux:
```bash
curl -fsSL https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.sh | sh
source ~/.zshrc  # or source ~/.bashrc
uds-cli login --token gfk_你的token --api-url https://api.goalfydata.ai
```

Windows (PowerShell):
```powershell
irm https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.ps1 | iex
uds-cli login --token gfk_你的token --api-url https://api.goalfydata.ai
```

## 第 3 步 — 安装插件

Codex CLI：
```bash
codex plugin marketplace add GoalfyAI/goalfydata
codex plugin add goalfydata@goalfydata
```

Codex 桌面版：把本文档全文粘贴到对话中，Codex 会自行执行安装命令并完成配置。

## 第 4 步 — 配置 Token

Codex 桌面版是 Electron 应用，不会继承终端环境变量。需要将 token 写入 `~/.codex/.env`：

```bash
# ~/.codex/.env
GOALFY_UDS_API_TOKEN=gfk_你的token
```

配置后重启 Codex 桌面版生效。

Codex CLI（终端）也可使用标准 shell export：

```bash
export GOALFY_UDS_API_TOKEN="gfk_你的token"
```

> 这一步必须做，否则 MCP 连接会因认证失败而报错。

## 第 5 步 — 重启 Codex

完全退出并重新打开 Codex，让插件和 MCP 生效。

## 第 6 步 — 验证

在 Codex 中确认 `goalfydata-mcp` 已连接，工具列表中有 20 个工具（`uds_query`、`uds_dataset_manage` 等）。

如果连接失败：
- 确认 `~/.codex/.env` 中 `GOALFY_UDS_API_TOKEN` 已配置
- 确认 token 是有效的 `gfk_` 前缀
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

1. 检查 `~/.codex/.env` 中是否有 `GOALFY_UDS_API_TOKEN`
2. 确认 token 有效（到控制台验证）
3. 完全退出并重启 Codex

### uds-cli 命令找不到

安装后需要重新打开终端（或 `source ~/.zshrc`），让 PATH 生效。

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

## 下一步

- [核心概念](./concepts.zh-CN.md) — 理解 Build / Run / Share 架构
- [常见问题](../FAQ.zh-CN.md) — 更多问题解答
