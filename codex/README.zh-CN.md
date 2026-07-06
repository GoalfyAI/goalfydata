# GoalfyData — Codex Plugin

OpenAI Codex 插件，用于连接 GoalfyData 通用数据集服务。

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

```bash
codex plugin marketplace add GoalfyAI/goalfydata
codex plugin add goalfydata@goalfydata
```

Codex 桌面版用户：把 [AGENTS.zh-CN.md](./AGENTS.zh-CN.md) 全文粘贴到对话中（这是面向 Agent 的执行手册），Codex 会自行执行安装命令并完成配置。

## 认证

Codex Desktop 是 Electron 应用，不会继承终端环境变量。需要将 API Key 配置到 `~/.codex/.env`：

```bash
# ~/.codex/.env
GOALFY_UDS_API_KEY=gfk_your_api_key_here
```

配置后重启 Codex Desktop 生效。

Codex CLI（终端）也可使用标准 shell export：

```bash
export GOALFY_UDS_API_KEY="gfk_your_api_key_here"
```

MCP 工具和 uds-cli 共用同一个 API Key。

## 验证

重启 Codex 后确认 `goalfydata-mcp` 已连接，工具列表中有 20 个工具（`uds_query`、`uds_dataset_manage` 等）。

如果连接失败：
- 确认 `~/.codex/.env` 中 `GOALFY_UDS_API_KEY` 已配置
- 确认 API Key 有效（到 https://goalfydata.ai/settings 验证）
- 完全退出并重启 Codex

## 更新

### 插件更新

**marketplace 安装**：先刷新市场索引，再重新安装：

```bash
codex plugin marketplace upgrade goalfydata
codex plugin remove goalfydata@goalfydata
codex plugin add goalfydata@goalfydata
```

### uds-cli 更新

```bash
uds-cli self-update
```

## 更换 API Key

旧 Key 删除或需要轮换时，按顺序完成全部步骤（只做 login 不够：环境变量的优先级高于登录保存的配置，残留的旧值会让 uds-cli 和 MCP 继续使用旧 Key）。

最简单的方式：到官网集成页（ https://goalfydata.ai/integrations/codex ）重新复制接入文本发给你的 Agent，由它自动完成全部步骤。手动操作如下：

1. 到 [GoalfyData](https://goalfydata.ai/settings) 删除旧 Key，创建并复制新 Key
2. 重新登录：`uds-cli login --api-key gfk_新Key --api-url https://api.goalfydata.ai`
3. 把 `~/.codex/.env` 中 `GOALFY_UDS_API_KEY` 的值更新为新 Key
4. 完全退出并重新打开 Codex

## 使用

插件加载后，Codex 会根据任务自动激活 skill。也可手动调用：

```
/goalfydata 帮我创建一个数据集
```
