# GoalfyData — Cursor Plugin

Cursor 插件，用于连接 GoalfyData 通用数据集服务。

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

## 安装

安装前确保已完成上述前置条件（Token 创建 + uds-cli 安装并登录）。

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

安装后重启 Cursor，插件会自动加载 MCP 服务器和 Skills。

## 认证

> **Cursor 必须明文配 token**
>
> Cursor 是 GUI 应用，不会读取 `~/.zshrc` / `~/.bash_profile` 中 export 的环境变量。**禁止**使用 `${env:GOALFY_UDS_API_TOKEN}`——会解析为空导致 MCP 连接失败。**必须**将 token 明文写入 `mcp.json`。

打开插件目录下的 `mcp.json`，将 `gfk_YOUR_TOKEN_HERE` 替换为真实 token：

```json
{
  "mcpServers": {
    "goalfydata-mcp": {
      "type": "streamable-http",
      "url": "https://mcp.goalfydata.ai/mcp",
      "headers": {
        "Authorization": "Bearer gfk_YOUR_TOKEN_HERE"
      }
    }
  }
}
```

安全提示：明文 token **禁止**提交到 git。

## 验证

1. Cursor 设置 → MCP：`goalfydata-mcp` 状态为已连接（非 Error）
2. Chat 中输入「列出我的数据集」，Agent 会调用 MCP 工具返回结果

## 更新

### 插件更新

重新下载最新 [ZIP](https://github.com/GoalfyAI/goalfydata/raw/main/cursor/goalfydata-cursor.zip) 并覆盖，或用 git 拉取：

```bash
unzip -o goalfydata-cursor.zip -d ~/.cursor/plugins/goalfydata
```

更新后完全退出并重启 Cursor（MCP 服务器仅在启动时加载）。

如果在 Cursor Customize 页面添加了插件，也可以点击 **Refresh** 按钮刷新，或开启 **Auto Refresh** 自动跟踪仓库更新。

### uds-cli 更新

```bash
uds-cli self-update
```

## 使用

插件加载后，Cursor Agent 会根据任务自动激活 skill。也可手动调用：

```
/goalfydata 帮我创建一个数据集
```
