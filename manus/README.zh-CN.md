# GoalfyData — Manus 接入

> **注意：Manus 不支持把本文档粘贴给 Agent 自动完成安装。添加连接器和上传技能都必须由你在 Manus 网页界面手动操作，请按下面步骤逐步执行。**

Manus 是云端 agent，两块分开配：**工具（MCP）** 在插件页添加连接器；**技能（skill）** 上传技能文件。

## 第 1 步：获取 API Key

到 [GoalfyData 控制台](https://goalfydata.ai/settings) 创建 API Key（形如 `gfk_xxx`）。明文仅在创建时显示一次，请妥善保存。

## 第 2 步：添加 MCP 连接器（工具）

左侧 **插件** → 右上角 **创建** → 连接器区域选择添加方式，二选一：

### 方式 A：通过 JSON 导入 MCP（推荐）

点击 **通过 JSON 导入 MCP**，粘贴以下 JSON，把 `gfk_YOUR_API_KEY_HERE` 换成你的 API Key，保存即可。

```json
{
  "mcpServers": {
    "goalfydata-mcp": {
      "url": "https://mcp.goalfydata.ai/mcp",
      "transport": "streamable_http",
      "headers": {
        "Authorization": "Bearer gfk_YOUR_API_KEY_HERE"
      }
    }
  }
}
```

### 方式 B：自定义 MCP（表单逐格填）

点击 **自定义 MCP**，按表格逐项填写：

| 页面字段 | 填什么 |
|---|---|
| **服务器名称** | `GoalfyData` |
| **传输类型** | `HTTP`（保持默认） |
| **图标（可选）** | 留空，或粘一个 logo URL |
| **备注（可选）** | 留空或填用途说明 |
| **服务器 URL** | `https://mcp.goalfydata.ai/mcp` |
| **自定义 headers** | 点「+ 添加自定义 header」，加 1 条 |

自定义 header（认证，必填）：
- Key：`Authorization`
- Value：`Bearer gfk_你的真实api_key`

填完保存。

## 第 3 步：上传 Skill（技能）

左侧 **插件** → 右上角 **创建** → 技能区域 → **上传技能**。

Manus 要求上传 `.zip` 或 `.skill` 文件，且根目录下必须包含 `SKILL.md`。

**下载预构建 ZIP**：直接下载 [goalfydata-skill.zip](https://github.com/GoalfyAI/goalfydata/raw/main/manus/goalfydata-skill.zip)，跳到下方上传步骤。

**或手动打包**：

```bash
cd manus/skill
zip -r goalfydata-skill.zip SKILL.md references/
```

将生成的 `goalfydata-skill.zip` 拖放到上传区域即可。

也可以选择 **从 GitHub 导入技能**，填入仓库地址 `GoalfyAI/goalfydata`，指定 `manus/skill/` 路径导入。

Manus 自动读取注册；对话里也能用 `/goalfydata` 主动调用。

## 验证

连接器状态已连 + Skills 里出现 `goalfydata` → 对话里说「列出我的数据集」即可。

## 更新

### Skill 更新

MCP 连接器指向远程服务，无需更新。Skill 文件需要手动更新：

1. Skills 管理页面删除旧的 `goalfydata` Skill
2. 重新打包并上传最新的 `skill/` 目录（`zip -r goalfydata-skill.zip SKILL.md references/`）
3. 关闭当前对话，重新打开（Skill 仅在会话开始时加载）


## 更换 API Key

旧 Key 删除或需要轮换时：

1. 到 [GoalfyData 控制台](https://goalfydata.ai/settings) 删除旧 Key，创建并复制新 Key
2. 在 Manus 连接器配置中，把 `Authorization` 的值更新为 `Bearer gfk_新Key` 并保存
3. 关闭当前对话，重新打开（连接器配置在新会话生效）

## 连不上时排查

1. **服务器 URL 必须公网可达** — Manus 在它自己的云上跑，够不到内网。这是最常见原因。
2. **API Key** 填错或漏了 `Bearer ` 前缀。
3. 传输类型先用 `HTTP`，不行再看 Manus 有没有 `Streamable HTTP` 选项。
