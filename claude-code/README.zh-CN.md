# GoalfyData — Claude Code Plugin

Claude Code 插件，用于连接 GoalfyData 通用数据集服务。

## 功能

- 构建结构化数据集（CSV/Excel/API/脚本）
- 数据分析（多轮 SQL 查询、聚合统计、趋势对比）
- 导入、查询、分享数据集
- 配置定时自动同步
- 部署数据应用到公网

## 前置条件

1. **GoalfyData API Key**: 到 https://goalfydata.ai/settings 创建
2. **uds-cli**:

   macOS / Linux:
   ```bash
   curl -fsSL https://cdn.goalfydata.ai/dataset-uds/install.sh | sh
   # 若提示 command not found：用 "$HOME/.goalfy/bin/uds-cli" 代替 uds-cli
   uds-cli login --api-key gfk_xxx --api-url https://api.goalfydata.ai
   ```

## 安装

安装前确保已完成上述前置条件（API Key 创建 + uds-cli 安装并登录）。

### 方式 1：通过 marketplace（推荐）

marketplace 安装会自动处理插件结构、MCP 配置和 Skill 加载，无需手动复制文件。

```bash
claude plugin marketplace add GoalfyAI/goalfydata
claude plugin install goalfydata@goalfydata
```

### 方式 2：Git clone + 本地 marketplace

克隆仓库后添加为本地 marketplace——走插件机制安装，MCP 和 Skill 都能正常加载：

```bash
git clone https://github.com/GoalfyAI/goalfydata.git
claude plugin marketplace add ./goalfydata
claude plugin install goalfydata@goalfydata
```

> **禁止手动把文件复制到 `~/.claude/skills/`。** skills 目录下的 `.mcp.json` 不会被 Claude Code 读取，MCP 连接会静默失败。

### 方式 3：本地开发测试

```bash
claude --plugin-dir ./claude-code
```

安装后重启 Claude Code，插件会自动加载 MCP 服务器。

## 认证

MCP 连接需要 `GOALFY_UDS_API_KEY` 环境变量。Claude Code 支持 `${VAR}` 展开，会自动注入到请求头。

**配置方式（按优先级，选一种即可）**：

1. **Claude Code settings.json（推荐，所有启动方式都生效）**：
   在 `~/.claude/settings.json` 的 `env` 中添加：
   ```json
   {
     "env": {
       "GOALFY_UDS_API_KEY": "gfk_your_api_key_here"
     }
   }
   ```

2. **Shell 环境变量（仅从终端启动 `claude` 时生效）**：
   ```bash
   export GOALFY_UDS_API_KEY="gfk_your_api_key_here"  # 加到 ~/.zshrc 或 ~/.bashrc
   ```

   注意：从桌面应用或 IDE 启动 Claude Code 时不会 source shell 配置文件，此方式不生效。

## 验证

重启 Claude Code 后输入 `/mcp`，确认 `goalfydata-mcp` 状态为 connected + 20 tools。

如果连接失败：
- 确认 `~/.claude/settings.json` 中 `GOALFY_UDS_API_KEY` 已配置
- 确认 API Key 是有效的 `gfk_` 前缀
- 完全退出 Claude Code 重新启动

## 更新

### 插件更新

**marketplace 安装（自动更新）**：marketplace 插件在 Claude Code 启动时自动检查更新。也可手动更新：

```bash
claude plugin update goalfydata@goalfydata
```

**本地 marketplace 安装**：拉取最新代码后刷新 marketplace：

```bash
cd goalfydata && git pull
claude plugin marketplace update goalfydata
```

更新后在会话中执行 `/reload-plugins` 重新加载，或重启 Claude Code。

### uds-cli 更新

```bash
uds-cli self-update
```

输出 `already on the latest version` 或 `update succeeded: <旧版本> → <新版本>` 均为正常；若提示 API URL 未配置，改用 `uds-cli self-update --api-url https://api.goalfydata.ai`。

## 更换 API Key

旧 Key 删除或需要轮换时，按顺序完成全部步骤（只做 login 不够：环境变量的优先级高于登录保存的配置，残留的旧值会让 uds-cli 和 MCP 继续使用旧 Key）。

最简单的方式：到官网集成页（ https://goalfydata.ai/integrations/claude-code ）重新复制接入文本发给你的 Agent，由它自动完成全部步骤。手动操作如下：

1. 到 [GoalfyData](https://goalfydata.ai/settings) 删除旧 Key，创建并复制新 Key
2. 重新登录：`uds-cli login --api-key gfk_新Key --api-url https://api.goalfydata.ai`
3. 把 `~/.claude/settings.json` 中 `GOALFY_UDS_API_KEY` 的值更新为新 Key
4. 完全退出并重新打开 Claude Code

> 为什么必须重启：login 保存的配置立即生效，但配置文件注入的环境变量和 MCP 连接只在完全重启后才切换为新 Key。重启后可用 `uds-cli whoami` 确认显示的 Key 前缀已是新值。

## 使用

插件加载后，Claude Code 会根据任务自动激活 skill。也可以手动调用：

```
/goalfydata 帮我创建一个数据集
```
