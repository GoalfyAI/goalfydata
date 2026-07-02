# Cursor 快速开始

3 分钟完成安装，让 Cursor 帮你构建实时数据资产。

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

## 第 3 步 — 安装插件

### 方式 1：下载 ZIP

下载 [goalfydata-cursor.zip](https://github.com/GoalfyAI/goalfydata/raw/main/cursor/goalfydata-cursor.zip)，解压并复制到插件目录：

```bash
unzip goalfydata-cursor.zip -d ~/.cursor/plugins/goalfydata
```

### 方式 2：Git clone

```bash
git clone https://github.com/GoalfyAI/goalfydata.git
cp -r goalfydata/cursor ~/.cursor/plugins/goalfydata
```

## 第 4 步 — 配置 Token

> Cursor 是 GUI 应用，不会读取 `~/.zshrc` 中 export 的环境变量。必须将 token 明文写入 `mcp.json`。

打开 `~/.cursor/plugins/goalfydata/mcp.json`，将 `gfk_YOUR_TOKEN_HERE` 替换为你的真实 token：

```json
{
  "mcpServers": {
    "goalfydata-mcp": {
      "type": "streamable-http",
      "url": "https://mcp.goalfydata.ai/mcp",
      "headers": {
        "Authorization": "Bearer gfk_你的真实token"
      }
    }
  }
}
```

> 安全提示：明文 token 禁止提交到 git。

## 第 5 步 — 重启 Cursor

完全退出并重新打开 Cursor，让插件和 MCP 生效。

## 第 6 步 — 验证

Cursor 设置 → MCP：确认 `goalfydata-mcp` 状态为已连接（非 Error）。

如果显示 Error：
- 确认 `mcp.json` 中是真实的 `gfk_` token 明文，不是占位符
- 确认 URL 正确：`https://mcp.goalfydata.ai/mcp`
- 完全退出 Cursor 重新启动

## 开始使用

验证通过后，在 Cursor Chat 中直接告诉 Agent 你想做什么：

### 从文件创建数据集

```
帮我把这个 CSV 文件创建成一个数据集
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

---

## 常见问题

### MCP 显示 Error

99% 是 token 问题。确认 `mcp.json` 中是真实的 `gfk_` token 明文，不是 `${env:...}` 也不是 `gfk_YOUR_TOKEN_HERE` 占位符。

### Skill 未加载

确认插件目录完整复制到 `~/.cursor/plugins/goalfydata/`，包含 `.cursor-plugin/`、`mcp.json`、`skills/` 三个部分。

### uds-cli 命令找不到

安装后需要重新打开终端（或 `source ~/.zshrc`），让 PATH 生效。

---

## 更新

### 插件更新

重新下载最新 [ZIP](https://github.com/GoalfyAI/goalfydata/raw/main/cursor/goalfydata-cursor.zip) 并覆盖：

```bash
unzip -o goalfydata-cursor.zip -d ~/.cursor/plugins/goalfydata
```

更新后完全退出并重启 Cursor（MCP 服务器仅在启动时加载）。

### uds-cli 更新

```bash
uds-cli self-update
```

---

## 下一步

- [核心概念](./concepts.zh-CN.md) — 理解 Build / Run / Share 架构
- [常见问题](../FAQ.zh-CN.md) — 更多问题解答
