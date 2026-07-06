# GoalfyData — 通用接入指南

适用于未被 Claude Code、Codex、Manus 覆盖的 AI 编程工具，或需要手动集成 GoalfyData 的场景。

如果你使用的是上述平台，请直接参考对应目录下的 README。

---

## 接入步骤

### 第 1 步：获取 API Key

到 [GoalfyData](https://goalfydata.ai/settings) 创建 API Key（形如 `gfk_xxx`）。

明文仅在创建时显示一次，请妥善保存。

### 第 2 步：安装 uds-cli

uds-cli 用于数据面操作（执行 SQL、导入数据、查看表结构）。

macOS / Linux:
```bash
curl -fsSL https://cdn.goalfydata.ai/dataset-uds/install.sh | sh
# 若提示 command not found：用 "$HOME/.goalfy/bin/uds-cli" 代替 uds-cli
uds-cli login --api-key gfk_你的api_key --api-url https://api.goalfydata.ai
```

### 第 3 步：配置 MCP 连接

将以下配置合并到你的工具对应的 MCP 配置文件中，将 `gfk_YOUR_API_KEY_HERE` 替换为真实 API Key：

```json
{
  "mcpServers": {
    "goalfydata-mcp": {
      "type": "streamable-http",
      "url": "https://mcp.goalfydata.ai/mcp",
      "headers": {
        "Authorization": "Bearer gfk_YOUR_API_KEY_HERE"
      }
    }
  }
}
```

不同工具的 MCP 配置格式可能有差异（字段名、传输类型写法等），按你的工具文档调整即可，核心是：

- **传输方式**：streamable-http
- **URL**：`https://mcp.goalfydata.ai/mcp`
- **认证**：API Key（gfk_ 前缀）通过 Authorization: Bearer 头传递

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

## 更换 API Key

旧 Key 删除或需要轮换时，按顺序完成全部步骤（只做 login 不够：环境变量的优先级高于登录保存的配置，残留的旧值会让 uds-cli 和 MCP 继续使用旧 Key）：

1. 到 [GoalfyData](https://goalfydata.ai/settings) 删除旧 Key，创建并复制新 Key
2. 重新登录：`uds-cli login --api-key gfk_新Key --api-url https://api.goalfydata.ai`
3. 把你的 MCP 配置中 `Authorization` 头（或对应环境变量）里的 Key 更新为新 Key
4. 完全重启你的 Agent 工具

> 为什么必须重启：login 保存的配置立即生效，但配置文件注入的环境变量和 MCP 连接只在完全重启后才切换为新 Key。重启后可用 `uds-cli whoami` 确认显示的 Key 前缀已是新值。

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
