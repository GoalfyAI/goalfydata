# GoalfyData — Codex Plugin

OpenAI Codex 插件，用于连接 GoalfyData 通用数据集服务。

## 功能

- 构建结构化数据集（CSV/Excel/API/脚本）
- 数据分析（多轮 SQL 查询、聚合统计、趋势对比）
- 导入、查询、分享数据集
- 配置定时自动同步
- 部署数据应用到公网

## 前置条件

1. **GoalfyData API Token**: 到 https://goalfydata.ai/settings 创建
2. **uds-cli**:

   macOS / Linux:
   ```bash
   curl -fsSL https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.sh | sh
   source ~/.zshrc  # or source ~/.bashrc
   uds-cli login --token gfk_xxx --api-url https://api.goalfydata.ai
   ```

   Windows (PowerShell):
   ```powershell
   irm https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.ps1 | iex
   uds-cli login --token gfk_xxx --api-url https://api.goalfydata.ai
   ```

## 安装

安装前确保已完成上述前置条件（Token 创建 + uds-cli 安装并登录）。

```bash
codex plugin marketplace add GoalfyAI/goalfydata
codex plugin add goalfydata@goalfydata
```

Codex 桌面版用户：把本 README 全文粘贴到对话中，Codex 会自行执行安装命令并完成配置。

## 认证

Codex Desktop 是 Electron 应用，不会继承终端环境变量。需要将 token 配置到 `~/.codex/.env`：

```bash
# ~/.codex/.env
GOALFY_UDS_API_TOKEN=gfk_your_token_here
```

配置后重启 Codex Desktop 生效。

Codex CLI（终端）也可使用标准 shell export：

```bash
export GOALFY_UDS_API_TOKEN="gfk_your_token_here"
```

MCP 工具和 uds-cli 共用同一套 token 体系。

## 验证

重启 Codex 后确认 `goalfydata-mcp` 已连接，工具列表中有 20 个工具（`uds_query`、`uds_dataset_manage` 等）。

如果连接失败：
- 确认 `~/.codex/.env` 中 `GOALFY_UDS_API_TOKEN` 已配置
- 确认 token 有效（到控制台验证）
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

## 使用

插件加载后，Codex 会根据任务自动激活 skill。也可手动调用：

```
/goalfydata 帮我创建一个数据集
```
