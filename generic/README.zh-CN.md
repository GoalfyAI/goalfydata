# GoalfyData — 通用接入指南

适用于未被 Claude Code、Cursor、Codex、Manus 覆盖的 AI 编程工具，或需要手动集成 GoalfyData 的场景。

如果你使用的是上述四个平台，请直接参考对应目录下的 README。

---

## 接入步骤

### 第 1 步：获取 API Token

到 [GoalfyData 控制台](https://goalfydata.ai/settings) 创建 API Key（形如 `gfk_xxx`）。

明文仅在创建时显示一次，请妥善保存。

### 第 2 步：安装 uds-cli

uds-cli 用于数据面操作（执行 SQL、导入数据、查看表结构）。

macOS / Linux:
```bash
curl -fsSL https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.sh | sh
source ~/.zshrc  # or source ~/.bashrc
uds-cli login --token gfk_你的token --api-url https://api.goalfydata.ai
```

### 第 3 步：配置 MCP 连接

将以下配置合并到你的工具对应的 MCP 配置文件中，将 `gfk_YOUR_TOKEN_HERE` 替换为真实 token：

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

不同工具的 MCP 配置格式可能有差异（字段名、传输类型写法等），按你的工具文档调整即可，核心是：

- **传输方式**：streamable-http
- **URL**：`https://mcp.goalfydata.ai/mcp`
- **认证**：Bearer Token 放在 Authorization header

### 第 4 步：加载 Skill

下载 [goalfydata-generic.zip](https://github.com/GoalfyAI/goalfydata/raw/main/generic/goalfydata-generic.zip) 并解压，或 clone 仓库后使用 `generic/` 目录。

将 `SKILL.md` 和 `references/` 目录导入你的工具。根据平台支持的方式选择：

| 平台能力 | 操作 |
|---|---|
| 支持 skill/技能上传 | 直接上传 `SKILL.md` + `references/` 整个目录 |
| 支持系统提示词 | 将 `SKILL.md` 内容粘贴到系统提示词 |
| 支持知识库/文档附件 | 将所有 `.md` 文件作为参考文档导入 |

### 第 5 步：验证

在你的 Agent 中输入：

```
列出我的数据集
```

Agent 调用 MCP 工具返回数据集列表即为接入成功。

---

## 更新

### Skill 更新

MCP 连接指向远程服务，无需更新配置。Skill 文件需要重新拉取：

```bash
cd goalfydata && git pull
```

然后按第 4 步的方式重新导入最新的 `SKILL.md` 和 `references/` 到你的工具。

### uds-cli 更新

```bash
uds-cli self-update
```

---

## 目录结构

```
generic/
├── .mcp.json                              # MCP 服务器配置模板
├── SKILL.md                               # 核心技能文件（工具说明 + 执行流程 + 约束）
└── references/                            # 参考指南
    ├── dataset-building-guide.md          # 数据集构建指南
    ├── data-quality-guide.md              # 数据质量指南
    ├── scheduled-sync-guide.md            # 定时同步指南
    └── app-deploy-guide.md               # 应用部署指南
```

## 与平台特定版本的关系

`generic/` 是所有平台版本的上游源文件。各平台目录（`claude-code/`、`cursor/` 等）基于此适配各自的插件格式。修改 SKILL.md 或 references 时，需要同时更新所有平台目录。
