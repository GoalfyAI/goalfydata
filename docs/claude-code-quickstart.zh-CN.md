# Claude Code 快速开始

3 分钟完成安装，让 Claude Code 帮你构建实时数据资产。

> 想让 AI 自动安装？把 [AGENTS.zh-CN.md](../claude-code/AGENTS.zh-CN.md) 发给你的 Agent，由它完成全部步骤。

---

## 第 1 步 — 获取 API Key

到 [GoalfyData 控制台](https://goalfydata.ai/settings) 创建 API Key（形如 `gfk_xxx`）。

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

### 推荐：通过 marketplace 安装

marketplace 安装会自动处理插件结构、MCP 配置和 Skill 加载，无需手动复制文件。

```bash
claude plugin marketplace add GoalfyAI/goalfydata
claude plugin install goalfydata@goalfydata
```

### 备选：Git clone + 本地 marketplace

克隆仓库后添加为本地 marketplace——走插件机制安装，MCP 和 Skill 都能正常加载：

```bash
git clone https://github.com/GoalfyAI/goalfydata.git
claude plugin marketplace add ./goalfydata
claude plugin install goalfydata@goalfydata
```

> **禁止手动把文件复制到 `~/.claude/skills/`。** skills 目录下的 `.mcp.json` 不会被 Claude Code 读取，MCP 连接会静默失败。

## 第 4 步 — 配置 API Key

在 `~/.claude/settings.json` 的 `env` 中添加你的 API Key：

```json
{
  "env": {
    "GOALFY_UDS_API_KEY": "gfk_你的api_key"
  }
}
```

> 这一步必须做，否则 MCP 连接会失败。从桌面应用或 IDE 启动 Claude Code 时不会读取 shell 环境变量，只能通过 settings.json 配置。

## 第 5 步 — 重启 Claude Code

完全退出并重新打开 Claude Code，让插件和 MCP 生效。

## 第 6 步 — 验证

在 Claude Code 中输入 `/mcp`，确认 `goalfydata-mcp` 状态为 connected + 20 tools。

如果显示失败：
- 确认 `~/.claude/settings.json` 中 `GOALFY_UDS_API_KEY` 已配置
- 确认 API Key 是有效的 `gfk_` 前缀
- 完全退出 Claude Code 重新启动

## 开始使用

验证通过后，直接告诉 Claude Code 你想做什么：

### 从文件创建数据集

```
帮我把这个 Excel 文件创建成一个数据集
```

### 从 API 拉取数据并定时同步

```
创建一个电商数据集，包含 3 张表：
- products：从 https://dummyjson.com/products 拉取
- users：从 https://dummyjson.com/users 拉取
- orders：从 https://dummyjson.com/carts 拉取
配置每天凌晨 2 点自动同步。
```

### 查询和分析已有数据集

```
列出我的数据集
```

```
帮我分析订单表的趋势，按月统计销售额
```

### 开发数据应用

```
基于这个电商数据集，帮我开发一个仪表盘应用并部署到公网
```

### 分享数据集

```
把这个数据集分享给 xxx@example.com
```

---

## 常见问题

### MCP 显示 Error / 未连接

1. 检查 `~/.claude/settings.json` 中是否有 `GOALFY_UDS_API_KEY`
2. 确认 API Key 有效（到控制台验证）
3. 完全退出并重启 Claude Code

### uds-cli 命令找不到

重新打开终端让 PATH 生效；或直接用绝对路径 `"$HOME/.goalfy/bin/uds-cli"` 调用（Agent 的非交互 shell 不加载 rc 文件，绝对路径始终有效）。若 login 提示 `unknown flag: --api-key`，先执行 `uds-cli self-update` 升级。

### 换了 API Key 后操作仍失败

环境里（配置文件或终端 export）残留旧 Key，其优先级高于 login 保存的配置。按「更换 API Key」小节走完全部步骤并完全重启。

### 插件安装失败 "source type not supported"

执行 `claude plugin marketplace update goalfydata` 更新缓存后重试。

---

## 更新

### 插件更新

**marketplace 安装**：marketplace 插件在启动时自动检查更新。手动更新：

```bash
claude plugin update goalfydata@goalfydata
```

**本地 marketplace 安装**：拉取最新代码后刷新 marketplace：

```bash
cd goalfydata && git pull
claude plugin marketplace update goalfydata
```

更新后执行 `/reload-plugins` 或重启 Claude Code。

### uds-cli 更新

```bash
uds-cli self-update
```

---

## 更换 API Key

旧 Key 删除或需要轮换时，按顺序完成全部步骤（只做 login 不够：环境变量的优先级高于登录保存的配置，残留的旧值会让 uds-cli 和 MCP 继续使用旧 Key）。

最简单的方式：到官网集成页（ https://goalfydata.ai/integrations/claude-code ）重新复制接入文本发给你的 Agent，由它自动完成全部步骤。手动操作如下：

1. 到 [GoalfyData 控制台](https://goalfydata.ai/settings) 删除旧 Key，创建并复制新 Key
2. 重新登录：`uds-cli login --api-key gfk_新Key --api-url https://api.goalfydata.ai`
3. 把 `~/.claude/settings.json` 中 `GOALFY_UDS_API_KEY` 的值更新为新 Key
4. 完全退出并重新打开 Claude Code

---

## 下一步

- [核心概念](./concepts.zh-CN.md) — 理解 Build / Run / Share 架构
- [完整 SKILL 文档](../claude-code/skills/goalfydata/SKILL.md) — 详细的工具和执行流程
- [常见问题](../FAQ.zh-CN.md) — 更多问题解答
